
include(${BUNDLECONTENT_MODULE_DIR}/BundleContent/JC.cmake)

# set(NewLine "\n")
# set(${NewLine} "sd")
# set(other "")

# string(JSON out SET "{}" test "\"sd\"")
# string(JSON outLen MEMBER "${out}" 0)
# unset(outLen)
# get_cmake_property(vars VARIABLES)
set(BUNDLECONTENT_COMMON_ARGS "_bc_common")
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

    _make_valid_dir_name("${CacheKey}" CacheKey)
    set(${OutVar} "${CacheKey}" PARENT_SCOPE)
endfunction()

function(_BundleContent_ParseArguments BracketArgs OutForwardedArgs OutBuildConfigurations)
    set(ForwardedArgs "")
    set(CurrentConfig "")
    set(BuildConfigurations "")
    set(AllCMakeArgs "")

    foreach(Arg IN LISTS BracketArgs)
        if("${Arg}" MATCHES "CMAKE_ARGS_?([^]]*)")
            if("${CMAKE_MATCH_1}" STREQUAL "")
                set(CurrentConfig ${BUNDLECONTENT_COMMON_ARGS})
            else()
                string(TOLOWER "${CMAKE_MATCH_1}" ConfigLower)
                set(CurrentConfig "${ConfigLower}")
                list(APPEND BuildConfigurations "${ConfigLower}")
            endif()
        elseif(NOT "${CurrentConfig}" STREQUAL "")
            list(APPEND Build_${CurrentConfig}_Args "${Arg}")
            list(APPEND AllCMakeArgs "${Arg}")
        else()
            set(CurrentConfig "")
            list(APPEND ForwardedArgs "${Arg}")
        endif()
    endforeach()

    if("${AllCMakeArgs}" MATCHES "\\[-G[; \"]]")
        message(FATAL_ERROR "Bundler: Please specify cmake generator with optional GENERATOR option(without \"-G\"). It will allow bundler to cache builds between different configurations")
    endif()

    if("${AllCMakeArgs}" MATCHES "-DCMAKE_TOOLCHAIN_FILE=")
        message(FATAL_ERROR "Bundler: Please specify cmake toolchain with optional TOOLCHAIN option. It will allow bundler to cache builds between different configurations")
    endif()

    set(${OutForwardedArgs} "${ForwardedArgs}" PARENT_SCOPE)
    set(${OutBuildConfigurations} "${BuildConfigurations}" PARENT_SCOPE)

    set(IterConfigs "")
    list(APPEND IterConfigs ${BUNDLECONTENT_COMMON_ARGS} ${BuildConfigurations})

    foreach(Config IN LISTS IterConfigs)
        list(REMOVE_DUPLICATES Build_${Config}_Args)
        set(Build_${Config}_Args "${Build_${Config}_Args}" PARENT_SCOPE)
    endforeach()
endfunction()

function(BundleContent_Declare TargetName)
    set(Options PASSTHROUGH)
    set(OneValueArgs SOURCE_DIR BUNDLE_TARGET GENERATOR TOOLCHAIN CONFIGURATIONS)
    set(MultiValueArgs "")
    cmake_parse_arguments(PARSE_ARGV 1 BC_ARGS "${Options}" "${OneValueArgs}" "${MultiValueArgs}")

    set(PassthroughMode "${BC_ARGS_PASSTHROUGH}")
    # if(${BUNDLECONTENT_INSIDE_BUNDLECONTENT})
    #     message(STATUS "Bundler: Detected being inside another bundler, enabling passthrough mode")
    #     set(PassthroughMode TRUE)
    # endif()
    set(Generator "${BC_ARGS_GENERATOR}")
    set(Toolchain "${BC_ARGS_TOOLCHAIN}")

    _BundleContent_CheckBuildComponents(Generator Toolchain)

    set(UnparsedBracketArgs "")
    foreach(Arg IN LISTS BC_ARGS_UNPARSED_ARGUMENTS)
        list(APPEND UnparsedBracketArgs "[==[${Arg}]==]")
    endforeach()
    
    _BundleContent_ParseArguments("${UnparsedBracketArgs}" ForwardedArgs BuildConfigurations)

    _BundleContent_BuildCacheKey("${Generator}" "${Toolchain}" CacheKey)
    _BundleContent_EnsureCorrectCacheFile("${TargetName}" "${CacheKey}")

    _make_valid_dir_name("${TargetName}" EscTargetName)
    file(READ "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json" WholeCache)
    JC_ParseJson("${WholeCache}" ParsedCache)
    JC_Assign(ParsedCache.${CacheKey} CacheVar)

    set(TargetDirectory "${BC_ARGS_SOURCE_DIR}")

    if(NOT ForwardedArgs AND NOT TargetDirectory)
        message(FATAL_ERROR "Bundler: Needs SOURCE_DIR to work without download options")
    elseif(NOT TargetDirectory)
        set(TargetDirectory "${BUNDLECONTENT_DEPS_DIR}/${EscTargetName}-src")
    endif()

    if(NOT "${ForwardedArgs}" STREQUAL "")
        list(APPEND ForwardedArgs "[==[SOURCE_DIR]==]")
        list(APPEND ForwardedArgs "[==[${TargetDirectory}]==]")
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

        if(NOT ${Build_${ConfigStringLower}})
            list(APPEND BuildConfigurations "${ConfigString}")
            set(Build_${ConfigStringLower} ON)
        endif()
    endforeach()

    foreach(ConfigString IN LISTS BUNDLECONTENT_DEFAULT_MAPPING)
        string(TOLOWER "${ConfigString}" ConfigStringLower)
        _set_if_undefined(${ConfigStringLower}_MappedName "${ConfigString}")
    endforeach()

    foreach(ConfigString IN LISTS BUNDLECONTENT_BUILD_MISSING)
        string(TOLOWER "${ConfigString}" ConfigStringLower)

        if(NOT ${Build_${ConfigStringLower}})
            list(APPEND BuildConfigurations "${ConfigString}")
            set(Build_${ConfigStringLower} ON)
        endif()
    endforeach()

    foreach(ConfigString IN LISTS BuildConfigurations)
        string(TOLOWER "${ConfigString}" ConfigStringLower)
        _BundleContent_SaveConfiguration(CacheVar "${${ConfigStringLower}_MappedName}" "${Build_${ConfigStringLower}_Args}")
    endforeach()
    
    _BundleContent_SetIfDifferent(CacheVar common_args "${Build_${BUNDLECONTENT_COMMON_ARGS}_Args}")
    _BundleContent_SetIfDifferent(CacheVar target_directory "${TargetDirectory}")
    _BundleContent_SetIfDifferent(CacheVar generator "${Generator}")
    _BundleContent_SetIfDifferent(CacheVar toolchain "${Toolchain}")
    _BundleContent_SetIfDifferent(CacheVar bundle_target_name "${ProjectTargetName}")
    _BundleContent_SetIfDifferent(CacheVar forwarded_args "${ForwardedArgs}")
    set(CacheVar.passthrough_mode "${PassthroughMode}")

    if("${CacheVar.output_directory_name}" STREQUAL "")
        _BundleContent_GenerateOutputDirectory("${Generator}" OutputDirectory)
        _BundleContent_SetIfDifferent(CacheVar output_directory_name "${OutputDirectory}")
    endif()

    JC_Assign(CacheVar ParsedCache.${CacheKey})

    JC_OutputJson(ParsedCache WholeCache PRETTY)
    file(WRITE "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json" "${WholeCache}")
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

    if(NOT "${HasConfigErr}" STREQUAL "NOTFOUND")
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
        common_args ""
        target_directory ""
        generator ""
        toolchain ""
        bundle_target_name ""
        output_directory_name ""
        passthrough_mode FALSE
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
            list(APPEND FoundOutputDirectories "${ParsedCache.${ParsedCacheKey}.output_directory_name}")
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

macro(BundleContent_MakeAvailable)
    block(SCOPE_FOR POLICIES)
    include(FetchContent)
    cmake_policy(SET CMP0077 NEW) # make option() do nothing if already defined
    
    set(_BC_VariablesToUnset "")
    set(_BC_PreviousInstalls "")
    set(_BC_CombineMakeAvailable "")
    list(APPEND _BC_VariablesToUnset "_BC_PreviousInstalls" "_BC_CombineMakeAvailable")

    foreach(TargetName ${ARGN})
        _make_valid_dir_name("${TargetName}" _BC_EscTargetName)
        _BundleContent_CheckStatus("${TargetName}" _BC_PassthroughMode _BC_ActiveConfig _BC_TargetDirectory _BC_OutputDirectoryName _BC_ReadyToUse)

        if(NOT ${_BC_PassthroughMode})
            _BundleContent_IterateTarget(
                "${_BC_PreviousInstalls}" 
                "${TargetName}" 
                "${_BC_ActiveConfig}" 
                "${_BC_TargetDirectory}"
                "${_BC_OutputDirectoryName}"
                "${_BC_ReadyToUse}" 
            )
        else()
            _BundleContent_IterateTargetPassthrough("${TargetName}")
        endif()

        list(APPEND _BC_VariablesToUnset 
            "_BC_EscTargetName"
            "_BC_PassthroughMode" 
            "_BC_ActiveConfig" 
            "_BC_TargetDirectory"
            "_BC_OutputDirectoryName" 
            "_BC_ReadyToUse"
        )
    endforeach()

    if(NOT "${_BC_CombineMakeAvailable}" STREQUAL "")
        FetchContent_MakeAvailable(${_BC_CombineMakeAvailable})
    endif()

    list(REMOVE_DUPLICATES _BC_VariablesToUnset)
    foreach(_BC_UnsetName IN LISTS _BC_VariablesToUnset)
        unset(${_BC_UnsetName})
        if(DEFINED ${_BC_VarName}_BC_Restore)
            set(${_BC_UnsetName} "${${_BC_VarName}_BC_Restore}")
            unset(${_BC_VarName}_BC_Restore)
        endif()
    endforeach()
    unset(_BC_VariablesToUnset)
    endblock()
endmacro()

macro(_BundleContent_IterateTarget PreviousInstalls TargetName ActiveConfig TargetDirectory OutputDirectoryName ReadyToUse)
    _make_valid_dir_name("${TargetName}" _BC_EscTargetName)
    if(NOT ${ReadyToUse})
        _BundleContent_BuildTarget("${PreviousInstalls}" "${TargetName}")
    else()
        message(STATUS "Bundler: ${TargetName} bundle is ready to use")
    endif()

    message(STATUS "Bundler: Finding package ${TargetName} for ${ActiveConfig}")

    set(_BC_TargetOutput "${BUNDLECONTENT_BASE_DIR}/${_BC_EscTargetName}/${OutputDirectoryName}")
    list(APPEND _BC_VariablesToUnset "_BC_TargetOutput" "_BC_EscTargetName")
    find_package(${TargetName} REQUIRED CONFIG GLOBAL PATHS "${_BC_TargetOutput}/${BUNDLECONTENT_INSTALL_DIR}/cmake/")

    list(APPEND _BC_PreviousInstalls "${TargetName}|${_BC_TargetOutput}/${BUNDLECONTENT_INSTALL_DIR}/cmake/")

    set(${TargetName}_POPULATED TRUE)
    set(${TargetName}_SOURCE_DIR "${TargetDirectory}")
    set(${TargetName}_BINARY_DIR "${_BC_TargetOutput}")
endmacro()

function(_BundleContent_CheckStatus TargetName OutPassthroughMode OutActiveConfig OutTargetDirectory OutOutputDirectoryName OutReadyToUse)
    _make_valid_dir_name("${TargetName}" EscTargetName)
    file(READ "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json" WholeCache)
    JC_ParseJson("${WholeCache}" ParsedCache)

    set(CacheVar "ParsedCache.${ParsedCache.active_config}")

    set(${OutPassthroughMode} "${${CacheVar}.passthrough_mode}" PARENT_SCOPE)
    set(${OutActiveConfig} "${ParsedCache.active_config}" PARENT_SCOPE)
    set(${OutTargetDirectory} "${${CacheVar}.target_directory}" PARENT_SCOPE)
    set(${OutOutputDirectoryName} "${${CacheVar}.output_directory_name}" PARENT_SCOPE)
    set(${OutReadyToUse} "${${CacheVar}.ready_to_use}" PARENT_SCOPE)

    if(${${CacheVar}.passthrough_mode})
        return()
    endif()

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

    set(${OutReadyToUse} "${${CacheVar}.ready_to_use}" PARENT_SCOPE)
endfunction()

function(_BundleContent_BuildTarget PreviousInstalls TargetName)
    _make_valid_dir_name("${TargetName}" EscTargetName)
    set(CacheFile "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json")
    file(READ "${CacheFile}" WholeCache)

    JC_ParseJson("${WholeCache}" ParsedCache)
    set(CacheVar "ParsedCache.${ParsedCache.active_config}")
    set(ConfigsVar "${CacheVar}.build_configurations")

    if(NOT "${${CacheVar}.forwarded_args}" STREQUAL "")
        message(STATUS "Bundler: Forwarding args to \"FetchContent\"")
        string(JOIN " " ForwardedArgs ${${CacheVar}.forwarded_args})
        message(STATUS "Bundler: ${ForwardedArgs}")
        cmake_language(EVAL CODE "
            block(SCOPE_FOR VARIABLES)
            include(FetchContent)
            FetchContent_Declare(${TargetName} 
                ${ForwardedArgs} 
                SOURCE_SUBDIR this-directory-does-not-exist
            )
            FetchContent_MakeAvailable(${TargetName})
            endblock()
        ")
    endif()

    set(TargetDir "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/${${CacheVar}.output_directory_name}")
    set(ReleaseArgs "")
    set(AllConfigs "${${CacheVar}.build_configurations}")
    # string(REPLACE ";" "\;" AllConfigs "${AllConfigs}")
    # string(REPLACE ";" "\;" PreviousInstalls "${PreviousInstalls}")

    foreach(Config IN LISTS ${CacheVar}.build_configurations)
        string(TOLOWER "${Config}" ConfigLower)
        _BundleContent_GetArgs("${CacheVar}" "${Config}" Args)

        list(APPEND Args
            "[===[-DEXPORT_NAME=${TargetName}]===]"
            "[===[-DCONFIGURATIONS=${AllConfigs}]===]"
        )

        if(NOT "${PreviousInstalls}" STREQUAL "")
            list(APPEND Args "[===[-DPREVIOUS=${PreviousInstalls}]===]")
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
    set(TargetDir "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/${${CacheVar}.output_directory_name}")

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
    set(Args ${${CacheVar}.common_args})
    list(APPEND Args ${${CacheVar}.build_configurations.${Config}.args})
    list(REMOVE_DUPLICATES Args)

    if(NOT "${Args}" MATCHES "CMAKE_BUILD_TYPE")
        list(PREPEND Args "-DCMAKE_BUILD_TYPE=${Config}")
    endif()

    list(APPEND Args
        "[===[-DPROJECT_PATH=${${CacheVar}.target_directory}]===]"
        "[===[-DTARGET_TO_BUNDLE=${${CacheVar}.bundle_target_name}]===]"
        "[===[-DUTILS_FILE=${BUNDLECONTENT_MODULE_DIR}/BundleContent/BundleContent_Utils.cmake]===]"
        "-G" "[===[${${CacheVar}.generator}]===]"
    )

    if(NOT "${${CacheVar}.toolchain}" STREQUAL "")
        list(APPEND Args "--toolchain" "[===[${${CacheVar}.toolchain}]===]")
    endif()

    set(${OutList} "${Args}" PARENT_SCOPE)
endfunction()

macro(_BundleContent_IterateTargetPassthrough TargetName)
    _BundleContent_ForwardGetArgs("${TargetName}" _BC_TargetDirectory _BC_VarPair _BC_ForwardedArgs)
    list(APPEND _BC_VariablesToUnset "_BC_TargetDirectory" "_BC_VarPair" "_BC_ForwardedArgs")

    block(SCOPE_FOR VARIABLES)
    foreach(KeyValuePair IN LISTS _BC_VarPair)

        if("${KeyValuePair}" MATCHES [==[^\[?=*\[?-D([^=]+)=([^]]*)\]?=*\]?$]==])
            set(VarName "${CMAKE_MATCH_1}")
            set(VarValue "${CMAKE_MATCH_2}")
            if(DEFINED ${VarName} AND NOT DEFINED ${VarName}_BC_Restore)
                set(${VarName}_BC_Restore "${${VarName}}" PARENT_SCOPE)
                set(${VarName}_BC_Restore "${${VarName}}")
            endif()
            set(${VarName} "${VarValue}" PARENT_SCOPE)
    
            list(APPEND _BC_VariablesToUnset "${VarName}")
        endif()
    endforeach()

    set(_BC_VariablesToUnset "${_BC_VariablesToUnset}" PARENT_SCOPE)
    endblock()
    
    if("${_BC_ForwardedArgs}" STREQUAL "")
        add_subdirectory(${_BC_TargetDirectory})
    else()
        string(JOIN " " _BC_ForwardedArgs ${_BC_ForwardedArgs})
        cmake_language(EVAL CODE "FetchContent_Declare(${TargetName} ${_BC_ForwardedArgs})")
        list(APPEND _BC_CombineMakeAvailable "${TargetName}")
    endif()
endmacro()

function(_BundleContent_ForwardGetArgs TargetName OutTargetDirectory OutVarPair OutForwardedArgs)
    _make_valid_dir_name("${TargetName}" EscTargetName)
    file(READ "${BUNDLECONTENT_BASE_DIR}/${EscTargetName}/bundler_cache.json" WholeCache)
    JC_ParseJson("${WholeCache}" ParsedCache)
    set(CacheVar "ParsedCache.${ParsedCache.active_config}")

    string(TOUPPER "${CMAKE_BUILD_TYPE}" ConfigUpper)

    set(CurrentConfig "")
    foreach(Config IN LISTS ParsedCache.${ParsedCache.active_config}.build_configurations)
        string(TOUPPER "${Config}" PossibleConfigUpper)
        if("${PossibleConfigUpper}" STREQUAL "${ConfigUpper}")
            set(CurrentConfig "${Config}")
            break()
        endif()
    endforeach()

    set(Args ${${CacheVar}.common_args})
    if(NOT "${CurrentConfig}" STREQUAL "")
        list(APPEND Args ${${CacheVar}.build_configurations.${CurrentConfig}.args})
    endif()
    list(REMOVE_DUPLICATES Args)
    
    set(${OutTargetDirectory} "${${CacheVar}.target_directory}" PARENT_SCOPE)
    set(${OutVarPair} "${Args}" PARENT_SCOPE)
    set(${OutForwardedArgs} "${${CacheVar}.forwarded_args}" PARENT_SCOPE)
endfunction()
