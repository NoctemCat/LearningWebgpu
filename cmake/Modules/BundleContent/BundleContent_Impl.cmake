
include(${BUNDLECONTENT_MODULE_DIR}/BundleContent/JC.cmake)

# set(NewLine "\n")
# set(${NewLine} "sd")
# set(other "")

# string(JSON out SET "{}" test "\"sd\"")
# string(JSON outLen MEMBER "${out}" 0)
# unset(outLen)
# get_cmake_property(vars VARIABLES)
function(_BundleContent_CheckBuildComponents GeneratorVar ToolchainVar)
    if("${${GeneratorVar}}" STREQUAL "" AND DEFINED CMAKE_GENERATOR)
        set(${GeneratorVar} "${CMAKE_GENERATOR}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Bundler: either pass GENERATOR or CMAKE_GENERATOR must be present")
    endif()

    if("${${ToolchainVar}}" STREQUAL "" AND NOT "${BUNDLECONTENT_CMAKE_TOOLCHAIN_FILE}" STREQUAL "")
        set(${ToolchainVar} "${BUNDLECONTENT_CMAKE_TOOLCHAIN_FILE}" PARENT_SCOPE)
    endif()
endfunction()

function(_BundleContent_BuildCacheKey Generator Toolchain OutVar)
    cmake_path(GET Toolchain FILENAME ToolchainFilename)

    set(CacheKey "${Generator}")

    if(NOT "${ToolchainFilename}" STREQUAL "")
        string(APPEND CacheKey "${BUNDLECONTENT_KEY_SEPARATOR}${ToolchainFilename}")
    endif()

    string(REPLACE " " "${BUNDLECONTENT_SPACE_REPLACEMENT}" CacheKey "${CacheKey}")
    set(${OutVar} "${CacheKey}" PARENT_SCOPE)
endfunction()

function(_BundleContent_ParseArguments Args OutQuotedArgs OutBuildConfigurations)
    set(QuotedArgs "")
    set(CurrentConfig "")
    set(BuildConfigurations "")
    set(AllCMakeArgs "")

    while(Args)
        list(POP_FRONT Args Arg)

        if("${Arg}" MATCHES "CMAKE_ARGS_?(.*)")
            if("${CMAKE_MATCH_1}" STREQUAL "")
                set(CurrentConfig "Build_common")
            else()
                string(TOLOWER "${CMAKE_MATCH_1}" ConfigLower)
                set(CurrentConfig "Build_${ConfigLower}")
                list(APPEND BuildConfigurations "${ConfigLower}")
            endif()
        elseif(NOT "${CurrentConfig}" STREQUAL "")
            list(APPEND ${CurrentConfig}_Args "${Arg}")
            list(APPEND AllCMakeArgs "${Arg}")
        else()
            set(CurrentConfig "")
            string(APPEND QuotedArgs " [===[${Arg}]===]")
        endif()
    endwhile()

    if("${AllCMakeArgs}" MATCHES "-G;|-G |-G\"")
        message(FATAL_ERROR "Bundler: Please specify cmake generator with optional GENERATOR option(without \"-G\"). It will allow bundler to cache builds between different configurations")
    endif()

    if("${AllCMakeArgs}" MATCHES "CMAKE_TOOLCHAIN_FILE")
        message(FATAL_ERROR "Bundler: Please specify cmake toolchain with optional TOOLCHAIN option. It will allow bundler to cache builds between different configurations")
    endif()

    set(${OutQuotedArgs} "${QuotedArgs}" PARENT_SCOPE)
    set(${OutBuildConfigurations} "${BuildConfigurations}" PARENT_SCOPE)

    set(IterConfigs "")
    list(APPEND IterConfigs "common" ${BuildConfigurations})

    foreach(Config IN LISTS IterConfigs)
        set(Build_${Config}_Args "${Build_${Config}_Args}" PARENT_SCOPE)
    endforeach()
endfunction()

function(BundleContent_Declare TargetName)
    set(Options "")
    set(OneValueArgs SOURCE_DIR BUNDLE_TARGET GENERATOR TOOLCHAIN CONFIGURATIONS)
    set(MultiValueArgs "")
    cmake_parse_arguments(PARSE_ARGV 1 BC_ARGS "${Options}" "${OneValueArgs}" "${MultiValueArgs}")

    set(Generator "${BC_ARGS_GENERATOR}")
    set(Toolchain "${BC_ARGS_TOOLCHAIN}")

    _BundleContent_CheckBuildComponents(Generator Toolchain)
    _BundleContent_ParseArguments("${BC_ARGS_UNPARSED_ARGUMENTS}" QuotedArgs BuildConfigurations)

    _BundleContent_BuildCacheKey("${Generator}" "${Toolchain}" CacheKey)
    _BundleContent_EnsureCorrectCacheFile("${TargetName}" "${CacheKey}")

    _make_valid_dir_name("${TargetName}" EscTargetName)
    file(READ "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json" WholeCache)
    JC_ParseJson("${WholeCache}" ParsedCache)
    JC_Assign(ParsedCache.${CacheKey} CacheVar)

    set(TargetDirectory "${BC_ARGS_SOURCE_DIR}")

    if(NOT QuotedArgs AND NOT TargetDirectory)
        message(FATAL_ERROR "Bundler: Needs SOURCE_DIR to work without download options")
    elseif(NOT TargetDirectory)
        set(TargetDirectory "${BUNDLECONTENT_DEPS_DIR}/${EscTargetName}-src")
    endif()

    if(NOT "${QuotedArgs}" STREQUAL "")
        string(APPEND QuotedArgs " [===[SOURCE_DIR]===]")
        string(APPEND QuotedArgs " [===[${TargetDirectory}]===]")

        if(NOT "${CacheVar.forwarded_args}" STREQUAL "${QuotedArgs}")
            message(STATUS "Bundler: Forwarding args to \"FetchContent\"")
            message(STATUS "Bundler:${QuotedArgs}")
            cmake_language(EVAL CODE "
                include(FetchContent)
                FetchContent_Declare(${TargetName} ${QuotedArgs})
                FetchContent_GetProperties(${TargetName})
                if(NOT ${TargetName}_POPULATED)
                    FetchContent_Populate(${TargetName})
                endif()
            ")

            set(CacheVar.forwarded_args "${QuotedArgs}")
            set(CacheVar.needs_rebuild TRUE)
        endif()
    endif()

    set(ProjectTargetName "${BC_ARGS_BUNDLE_TARGET}")

    if(NOT ProjectTargetName)
        set(ProjectTargetName "${TargetName}")
    endif()

    foreach(ConfigString IN LISTS BuildConfigurations)
        string(TOLOWER "${ConfigString}" ConfigStringLower)
        set(Build_${ConfigStringLower} ON)
    endforeach()

    foreach(ConfigString IN LISTS BC_ARGS_CONFIGURATIONS)
        string(TOLOWER "${ConfigString}" ConfigStringLower)
        set(${ConfigStringLower}_MappedName "${ConfigString}")

        if(NOT "${Build_${ConfigStringLower}}" STREQUAL "ON")
            list(APPEND BuildConfigurations "${ConfigString}")
        endif()
    endforeach()

    foreach(ConfigString IN LISTS BUNDLECONTENT_DEFAULT_MAPPING)
        string(TOLOWER "${ConfigString}" ConfigStringLower)
        _set_if_undefined(${ConfigStringLower}_MappedName "${ConfigString}")
    endforeach()

    if(NOT "${Build_release}" STREQUAL "ON")
        list(APPEND BuildConfigurations "Release")
    endif()

    if(NOT "${Build_debug}" STREQUAL "ON")
        list(APPEND BuildConfigurations "Debug")
    endif()

    foreach(ConfigString IN LISTS BuildConfigurations)
        string(TOLOWER "${ConfigString}" ConfigStringLower)
        set(ConfigArgs "")
        list(APPEND ConfigArgs ${Build_common_Args} ${Build_${ConfigStringLower}_Args})
        list(REMOVE_DUPLICATES ConfigArgs)
        _list_to_json_string("${ConfigArgs}" ConfigArgs)

        _BundleContent_SaveConfiguration(CacheVar "${${ConfigStringLower}_MappedName}" "${ConfigArgs}")
    endforeach()

    _BundleContent_SetIfDifferent(CacheVar target_directory "${TargetDirectory}")
    _BundleContent_SetIfDifferent(CacheVar generator "${Generator}")
    _BundleContent_SetIfDifferent(CacheVar toolchain "${Toolchain}")
    _BundleContent_SetIfDifferent(CacheVar bundle_target_name "${ProjectTargetName}")

    if("${CacheVar.output_directory}" STREQUAL "")
        _BundleContent_GenerateOutputDirectory("${Generator}" OutputDirectory)
        _BundleContent_SetIfDifferent(CacheVar output_directory "${OutputDirectory}")
    endif()

    JC_Assign(CacheVar ParsedCache.${CacheKey})

    JC_OutputJson(ParsedCache WholeCache PRETTY)
    file(WRITE "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json" "${WholeCache}")
endfunction()

function(BundleContent_MakeAvailable)
    set(PreviousInstalls "")

    foreach(TargetName IN LISTS ARGN)
        _make_valid_dir_name("${TargetName}" EscTargetName)
        _BundleContent_IterateTarget("${PreviousInstalls}" "${TargetName}" ActiveConfig TargetDirectory OutputDirectory)

        message(STATUS "Bundler: Finding package ${TargetName} for ${ActiveConfig}")

        set(TargetDir "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/${OutputDirectory}")
        find_package(${TargetName} REQUIRED CONFIG GLOBAL PATHS "${TargetDir}/${BUNDLECONTENT_INSTALL_DIR}/cmake/")

        list(APPEND PreviousInstalls "${TargetName}|${TargetDir}/${BUNDLECONTENT_INSTALL_DIR}/cmake/")

        set(${TargetName}_POPULATED TRUE PARENT_SCOPE)
        set(${TargetName}_SOURCE_DIR "${TargetDirectory}" PARENT_SCOPE)
        set(${TargetName}_BINARY_DIR "${TargetDir}" PARENT_SCOPE)
    endforeach()
endfunction()

function(_BundleContent_IterateTarget PreviousInstalls TargetName OutActiveConfig OutTargetDirectory OutOutputDirectory)
    _make_valid_dir_name("${TargetName}" EscTargetName)
    _BundleContent_CheckStatus("${TargetName}" ActiveConfig TargetDirectory OutputDirectory ReadyToUse)

    if(NOT ${ReadyToUse})
        _BundleContent_BuildTarget("${PreviousInstalls}" "${TargetName}")
    else()
        message(STATUS "Bundler: ${TargetName} bundle is ready to use")
    endif()

    set(${OutActiveConfig} "${ActiveConfig}" PARENT_SCOPE)
    set(${OutTargetDirectory} "${TargetDirectory}" PARENT_SCOPE)
    set(${OutOutputDirectory} "${OutputDirectory}" PARENT_SCOPE)
endfunction()

function(_BundleContent_CheckStatus TargetName OutActiveConfig OutTargetDirectory OutOutputDirectory OutStatus)
    _make_valid_dir_name("${TargetName}" EscTargetName)
    file(READ "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json" WholeCache)
    JC_ParseJson("${WholeCache}" ParsedCache)

    set(CacheVar "ParsedCache.${ParsedCache.active_config}")

    if(${${CacheVar}.needs_rebuild})
        message(STATUS "Bundler: ${TargetName} needs rebuild. Deleting build files...")
        set(${CacheVar}.needs_rebuild FALSE PARENT_SCOPE)
        set(${CacheVar}.needs_rebuild FALSE)
        set(${CacheVar}.ready_to_use FALSE PARENT_SCOPE)
        set(${CacheVar}.ready_to_use FALSE)

        foreach(Config IN LISTS ${CacheVar}.build_configurations)
            set(${CacheVar}.build_configurations.${Config}.is_built FALSE PARENT_SCOPE)
            set(${CacheVar}.build_configurations.${Config}.is_built FALSE)
        endforeach()

        _BundleContent_DeleteBuildFiles("${EscTargetName}" "${CacheVar}")
        JC_OutputJson(ParsedCache WholeCache PRETTY)
        file(WRITE "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json" "${WholeCache}")
    endif()

    set(${OutStatus} "${${CacheVar}.ready_to_use}" PARENT_SCOPE)
    set(${OutTargetDirectory} "${${CacheVar}.target_directory}" PARENT_SCOPE)
    set(${OutOutputDirectory} "${${CacheVar}.output_directory}" PARENT_SCOPE)
    set(${OutActiveConfig} "${ParsedCache.active_config}" PARENT_SCOPE)
endfunction()

function(_BundleContent_SaveConfiguration BaseConfigVar ConfigName ConfigArgs)
    set(ConfigPath "${BaseConfigVar}.build_configurations.${ConfigName}")

    if(DEFINED ${ConfigPath})
        if(NOT "${${ConfigPath}.args}" STREQUAL "${ConfigArgs}")
            set(${ConfigPath}.args "${ConfigArgs}" PARENT_SCOPE)
            set(${ConfigPath}.is_built FALSE PARENT_SCOPE)
            set(${BaseConfigVar}.needs_rebuild TRUE PARENT_SCOPE)
        endif()
    else()
        JC_CreateObject(configuration
            "args" STRING "${ConfigArgs}"
            "is_built" FALSE
        )
        JC_AssignParentScope(configuration ${BaseConfigVar}.build_configurations.${ConfigName})
        list(APPEND ${BaseConfigVar}.build_configurations "${ConfigName}")
        set(${BaseConfigVar}.build_configurations "${${BaseConfigVar}.build_configurations}" PARENT_SCOPE)

        set(${BaseConfigVar}.needs_rebuild TRUE PARENT_SCOPE)
    endif()
endfunction()

macro(_BundleContent_SetIfDifferent BaseConfigVar Property Value)
    if(NOT "${${BaseConfigVar}.${Property}}" STREQUAL "${Value}")
        set(${BaseConfigVar}.${Property} "${Value}")
        set(${BaseConfigVar}.needs_rebuild TRUE)
    endif()
endmacro()

function(_BundleContent_EnsureCorrectCacheFile TargetName CacheKey)
    _make_valid_dir_name("${TargetName}" EscTargetName)
    set(CacheFile "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json")

    if(NOT EXISTS "${CacheFile}")
        _BundleContent_CreateEmptyCache(${EscTargetName})
    endif()

    file(READ "${CacheFile}" WholeCache)
    string(JSON HasConfigString ERROR_VARIABLE HasConfigErr GET "${WholeCache}" active_config)

    if("${HasConfigString}" MATCHES "-?NOTFOUND\$")
        message(NOTICE "Bundler: Corrupted cache found! Recreating...")
        _BundleContent_CreateEmptyCache(${EscTargetName})
        file(READ "${CacheFile}" WholeCache)
    endif()

    string(JSON ConfigString ERROR_VARIABLE Err GET "${WholeCache}" ${CacheKey})

    if(NOT "${Err}" STREQUAL "NOTFOUND")
        message(NOTICE "Bundler: Configuration cache not found. Creating default...")
        _BundleContent_GetDefaultCache(DefaultJson)
        JC_ParseJson("${WholeCache}" ParsedCache)

        JC_Assign(DefaultJson ParsedCache.${CacheKey})
        list(APPEND ParsedCache "${CacheKey}")
        set(ParsedCache.active_config "${CacheKey}")

        JC_OutputJson(ParsedCache WholeCache PRETTY)
        file(WRITE "${CacheFile}" "${WholeCache}")
    endif()
endfunction()

function(_BundleContent_CreateEmptyCache EscTargetName)
    JC_CreateObject(EmptyCache active_config "")
    JC_OutputJson(EmptyCache EmptyCacheJson)
    file(WRITE "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json" "${EmptyCacheJson}")
endfunction()

function(_BundleContent_GetDefaultCache OutVar)
    JC_CreateObject(DefaultCache
        ready_to_use FALSE
        needs_rebuild TRUE
        build_configurations ""
        forwarded_args ""
        target_directory ""
        generator ""
        toolchain ""
        bundle_target_name ""
        output_directory ""
    )
    JC_CreateObject(DefaultCache.build_configurations)
    JC_AssignParentScope(DefaultCache ${OutVar})
endfunction()

function(_BundleContent_GenerateOutputDirectory Generator OutOutputDirectory)
    string(REPLACE " " ";" SplitGenerator "${Generator}")
    list(GET SplitGenerator 0 GeneratorFirstPart)

    set(FoundOutputDirectories "")

    foreach(ParsedCacheKey IN LISTS ParsedCache)
        if("${ParsedCacheKey}" MATCHES "^${GeneratorFirstPart}")
            list(APPEND FoundOutputDirectories "${ParsedCache.${ParsedCacheKey}.output_directory}")
        endif()
    endforeach()

    set(Idx 0)

    while(TRUE)
        if(NOT "${GeneratorFirstPart}_${Idx}" IN_LIST FoundOutputDirectories)
            set(${OutOutputDirectory} "${GeneratorFirstPart}_${Idx}" PARENT_SCOPE)
            return()
        endif()

        math(EXPR Idx "${Idx} + 1")
    endwhile()
endfunction()

function(_BundleContent_BuildTarget PreviousInstalls TargetName)
    _make_valid_dir_name("${TargetName}" EscTargetName)
    set(CacheFile "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json")
    file(READ "${CacheFile}" WholeCache)

    JC_ParseJson("${WholeCache}" ParsedCache)
    set(CacheVar "ParsedCache.${ParsedCache.active_config}")
    set(ConfigsVar "${CacheVar}.build_configurations")

    set(TargetDir "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/${${CacheVar}.output_directory}")
    set(ReleaseArgs "")
    set(AllConfigs "${${CacheVar}.build_configurations}")
    string(REPLACE ";" "," AllConfigs "${AllConfigs}")
    string(REPLACE ";" "||" PreviousInstalls "${PreviousInstalls}")

    foreach(Config IN LISTS ${CacheVar}.build_configurations)
        string(TOLOWER "${Config}" ConfigLower)
        _BundleContent_GetArgs("${CacheVar}" "${Config}" Args)

        list(APPEND Args
            "-DEXPORT_NAME=${TargetName}"
            "-DCONFIGURATIONS=${AllConfigs}"
        )

        if(NOT "${PreviousInstalls}" STREQUAL "")
            list(APPEND Args "-DPREVIOUS=${PreviousInstalls}")
        endif()

        if("${ConfigLower}" STREQUAL "release")
            set(ReleaseArgs "${Args}")
        endif()

        if(${${ConfigsVar}.${Config}.is_built})
            message(STATUS "Bundler: ${TargetName} ${Config} bundle found")
            continue()
        endif()

        message(STATUS "Bundler: ${TargetName} ${Config} bundle not found, building and bundling...")

        execute_sequential(COMMANDS
            ${CMAKE_COMMAND} -S . -B "${TargetDir}/${ConfigLower}" ${Args} <<
            ${CMAKE_COMMAND} --build "${TargetDir}/${ConfigLower}" --config "${Config}" <<
            ${CMAKE_COMMAND} --install "${TargetDir}/${ConfigLower}" --prefix "${TargetDir}/${BUNDLECONTENT_INSTALL_DIR}" --config "${Config}"
            COMMANDS_STOP
            WORKING_DIRECTORY "${BUNDLECONTENT_BASE_DIR}"
            COMMAND_ERROR_IS_FATAL ANY
        )

        set(${ConfigsVar}.${Config}.is_built TRUE)
        JC_OutputJson(ParsedCache WholeCache PRETTY)
        file(WRITE "${CacheFile}" "${WholeCache}")
    endforeach()

    message(STATUS "Bundler: finalizing ${TargetName} install...")
    execute_sequential(COMMANDS
        ${CMAKE_COMMAND} -S . -B "${TargetDir}/release" ${ReleaseArgs} <<
        ${CMAKE_COMMAND} --install "${TargetDir}/release" --prefix "${TargetDir}/${BUNDLECONTENT_INSTALL_DIR}" --config Package
        COMMANDS_STOP
        WORKING_DIRECTORY "${BUNDLECONTENT_BASE_DIR}"
        COMMAND_ERROR_IS_FATAL ANY
    )
    _delete_empty_directories_recurse("${TargetDir}/${BUNDLECONTENT_INSTALL_DIR}/include")

    set(${CacheVar}.ready_to_use TRUE)
    JC_OutputJson(ParsedCache WholeCache PRETTY)
    file(WRITE "${CacheFile}" "${WholeCache}")
endfunction()

function(_BundleContent_DeleteBuildFiles EscTargetName CacheVar)
    set(TargetDir "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/${${CacheVar}.output_directory}")

    if(NOT EXISTS ${TargetDir})
        return()
    endif()

    set(FilesToDelete "${TargetDir}/${BUNDLECONTENT_INSTALL_DIR}")

    foreach(Config IN LISTS ${CacheVar}.build_configurations)
        string(TOLOWER "${Config}" ConfigLower)

        file(GLOB BuildFiles "${TargetDir}/${ConfigLower}/*")
        list(FILTER BuildFiles EXCLUDE REGEX "/_deps\$")
        file(GLOB BuildFilesDeps "${TargetDir}/${ConfigLower}/_deps/*")
        list(FILTER BuildFilesDeps INCLUDE REGEX "-.*build\$")

        list(APPEND FilesToDelete ${BuildFiles} ${BuildFilesDeps})
    endforeach()

    foreach(Dir IN LISTS FilesToDelete)
        if(EXISTS ${Dir})
            file(REMOVE_RECURSE ${Dir})
        endif()
    endforeach()

    message(STATUS "Bundler: Build files deleted")
endfunction()

function(_BundleContent_GetArgs CacheVar Config OutList)
    set(Args "${${CacheVar}.build_configurations.${Config}.args}")
    _json_string_to_list("${Args}" Args)

    if(NOT "${Args}" MATCHES "CMAKE_BUILD_TYPE")
        list(PREPEND Args "-DCMAKE_BUILD_TYPE=${Config}")
    endif()

    list(APPEND Args
        "-DPROJECT_PATH=${${CacheVar}.target_directory}"
        "-DTARGET_TO_BUNDLE=${${CacheVar}.bundle_target_name}"
        "-DUTILS_FILE=${BUNDLECONTENT_MODULE_DIR}/BundleContent/BundleContent_Utils.cmake"
        "-G" "${${CacheVar}.generator}"
    )

    if(NOT "${${CacheVar}.toolchain}" STREQUAL "")
        list(APPEND Args "--toolchain" "${${CacheVar}.toolchain}")
    endif()

    set(${OutList} "${Args}" PARENT_SCOPE)
endfunction()

function(_delete_empty_directories_recurse DirPath)
    set(AllFiles "${DirPath}")
    list(POP_BACK AllFiles CurrentFile)
    set(FoldersToAdd "")

    while(NOT "${CurrentFile}" STREQUAL "")
        if("${CurrentFile}" STREQUAL "|")
            list(REMOVE_DUPLICATES FoldersToAdd)

            if(NOT "${FoldersToAdd}" STREQUAL "")
                list(APPEND AllFiles "${FoldersToAdd}")
            endif()

            set(FoldersToAdd "")

            list(POP_BACK AllFiles CurrentFile)
            continue()
        endif()

        if(IS_DIRECTORY "${CurrentFile}")
            # message(STATUS "Bundler: Iterating delete over ${CurrentFile}")
            file(GLOB CurrentFiles "${CurrentFile}/*")

            if("${CurrentFiles}" STREQUAL "")
                # message(STATUS "Bundler: Deleting empty folder ${CurrentFile}")
                file(REMOVE_RECURSE "${CurrentFile}")

                cmake_path(GET CurrentFile PARENT_PATH ParentFile)
                list(APPEND FoldersToAdd "${ParentFile}")
            else()
                list(APPEND AllFiles "|" "${CurrentFiles}")
            endif()
        endif()

        list(POP_BACK AllFiles CurrentFile)
    endwhile()
endfunction()
