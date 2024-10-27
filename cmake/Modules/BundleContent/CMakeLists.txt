cmake_minimum_required(VERSION 3.25...3.30)

option(PROJECT_PATH "Feature description" "")
option(TARGET_TO_BUNDLE "Feature description" "")
option(EXPORT_NAME "Feature description" "")
option(UTILS_FILE "Feature description" "")
option(CONFIGURATIONS "Feature description" "")
option(PREVIOUS "Feature description" "")

string(REPLACE "||" ";" PREVIOUS "${PREVIOUS}")
string(REPLACE "," ";" CONFIGURATIONS "${CONFIGURATIONS}")
list(TRANSFORM CONFIGURATIONS TOUPPER OUTPUT_VARIABLE ConfigsUpper)

if(MSVC)
    if(NOT "${CMAKE_CXX_FLAGS}" MATCHES "/MP")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MP")
    endif()
endif()

project(BundleContent_RootDir VERSION 1.0.0)

include(${UTILS_FILE})

if(NOT PROJECT_PATH)
    message(FATAL_ERROR "PROJECT_PATH is required")
endif()

string(TOLOWER "${CMAKE_BUILD_TYPE}" ConfigLower)
string(TOUPPER "${CMAKE_BUILD_TYPE}" ConfigUpper)

set(InstallDeps "")
set(InstallDepsFiles "")

if(NOT "${PREVIOUS}" STREQUAL "OFF")
    foreach(PrevInstallComb IN LISTS PREVIOUS)
        string(REPLACE "|" ";" PrevInstallComb "${PrevInstallComb}")
        list(GET PrevInstallComb 0 InstallName)
        list(GET PrevInstallComb 1 InstallCmakePath)

        find_package(${InstallName} REQUIRED CONFIG GLOBAL PATHS "${InstallCmakePath}")

        set(${InstallName}_DIR "${InstallCmakePath}")

        list(APPEND InstallDeps "${InstallName}")
        list(APPEND InstallDepsFiles ${${InstallName}_BUNDLE_FILENAMES})
    endforeach()
endif()

string(MAKE_C_IDENTIFIER "${TARGET_TO_BUNDLE}" BundleNameEscaped)
add_subdirectory("${PROJECT_PATH}" "${CMAKE_BINARY_DIR}/${BundleNameEscaped}_bundle" EXCLUDE_FROM_ALL)

if(NOT TARGET ${TARGET_TO_BUNDLE})
    message(FATAL_ERROR "TARGET_TO_BUNDLE must be a target from PROJECT_PATH")
endif()

# Wrapper so it could build interface libs
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/null_wrapper.cpp "")
add_library(Wrapper STATIC ${CMAKE_CURRENT_BINARY_DIR}/null_wrapper.cpp)
target_link_libraries(Wrapper PUBLIC ${TARGET_TO_BUNDLE})

set(TargetBundleName "${BundleNameEscaped}_bundle")

bundle_static_library_new(Wrapper "${TargetBundleName}" SharedLibs IncludeDirs)

include(GNUInstallDirs)

set(InstallIncludeDirs "")
set(InstallDirs "")
set(DirsCombined "")

# string(REPLACE ";" "\n" BeforeDirs "${IncludeDirs}")
# message(NOTICE "${BeforeDirs}\n\n")
# message(NOTICE "---------Processing:")
foreach(Directory IN LISTS IncludeDirs)
    if("${Directory}" MATCHES "^\\$<INSTALL_INTERFACE:([^🕳]+)>\$")
        list(APPEND InstallIncludeDirs "${CMAKE_MATCH_1}")
        continue()
    elseif("${Directory}" MATCHES "^\\$<BUILD_INTERFACE:([^🕳]+)>\$")
        set(FullPath "${CMAKE_MATCH_1}")
    else()
        set(FullPath "${Directory}")
    endif()

    string(STRIP "${FullPath}" FullPath)
    cmake_path(NORMAL_PATH FullPath OUTPUT_VARIABLE FullPath)

    if("${FullPath}" STREQUAL "")
        message(FATAL_ERROR "Trying to install an empty directory will lead to catastrophe. Figure out why this is empty: ${FullPath}")
    endif()

    if("${FullPath}" MATCHES "(.+)\\/include\$")
        set(InstallDirectory "${CMAKE_MATCH_1}")
        set(RelativePath "include")

    elseif("${FullPath}" MATCHES "(.+)\\/(include\\/.*)\$")
        set(InstallDirectory "${CMAKE_MATCH_1}")
        set(RelativePath "${CMAKE_MATCH_2}")

    elseif("${FullPath}" MATCHES ".+\\/.*src\$")
        set(InstallDirectory "${FullPath}")
        set(RelativePath "")

    elseif("${FullPath}" MATCHES "(.+\\/.*src)\\/(.*)\$")
        set(InstallDirectory "${CMAKE_MATCH_1}")
        set(RelativePath "${CMAKE_MATCH_2}")

    elseif("${FullPath}" MATCHES "(.+\\/_deps\\/[^/]+)\\/(.*)\$")
        message(NOTICE "CMAKE_MATCH_1 ${CMAKE_MATCH_1}")
        message(NOTICE "CMAKE_MATCH_2 ${CMAKE_MATCH_2}")
        message(FATAL_ERROR "Check if correct ${FullPath}")

        set(InstallDirectory "${CMAKE_MATCH_1}")
        set(RelativePath "${CMAKE_MATCH_2}")

    elseif("${FullPath}" MATCHES "^${CMAKE_BINARY_DIR}/${BundleNameEscaped}_bundle/")
        set(InstallDirectory "${CMAKE_BINARY_DIR}/${BundleNameEscaped}_bundle")
        cmake_path(RELATIVE_PATH FullPath BASE_DIRECTORY "${CMAKE_BINARY_DIR}/${BundleNameEscaped}_bundle" OUTPUT_VARIABLE RelativePath)

    elseif("${FullPath}" MATCHES "^${PROJECT_PATH}/")
        set(InstallDirectory "${PROJECT_PATH}")
        cmake_path(RELATIVE_PATH FullPath BASE_DIRECTORY "${PROJECT_PATH}" OUTPUT_VARIABLE RelativePath)

    else()
        message(FATAL_ERROR "Work on this ${FullPath}")
    endif()

    list(APPEND InstallDirs "${InstallDirectory}")
    list(APPEND InstallIncludeDirs "${RelativePath}")
    list(APPEND DirsCombined "${InstallDirectory}" "${RelativePath}")

    # message(NOTICE "Original: ${FullPath}")
    # message(NOTICE "Parsing: ${InstallDirectory}, RelDir: ${RelativePath}")
endforeach()

list(REVERSE DirsCombined)

while(DirsCombined)
    list(POP_BACK DirsCombined InstallDirectory RelativePath)

    if(NOT "${RelativePath}" STREQUAL "")
        set(InstallDirectory "${InstallDirectory}/${RelativePath}/")
        set(InstallDestination "${CMAKE_INSTALL_INCLUDEDIR}/${RelativePath}")
    else()
        set(InstallDirectory "${InstallDirectory}/")
        set(InstallDestination "${CMAKE_INSTALL_INCLUDEDIR}")
    endif()

    install(
        DIRECTORY "${InstallDirectory}"
        DESTINATION "${InstallDestination}"
        FILES_MATCHING
        PATTERN "*.h*"
        PATTERN "*.intermediate" EXCLUDE
        PATTERN "*.hlsl" EXCLUDE
        PATTERN "*.html" EXCLUDE
    )

    # message(NOTICE "Install: ${InstallDirectory}")
    # message(NOTICE "RelDir: ${RelativePath}, Destination: ${InstallDestination}")
endwhile()

# message(FATAL_ERROR "err")
set(CopyInstallDeps ${InstallDepsFiles})
list(TRANSFORM CopyInstallDeps PREPEND ".*")
string(REPLACE "." "\\." CopyInstallDeps "${CopyInstallDeps}")
string(TOLOWER "${CopyInstallDeps}" CopyInstallDeps)

foreach(Library IN LISTS SharedLibs)
    set_target_properties(${Library} PROPERTIES
        ${ConfigUpper}_POSTFIX "_${ConfigLower}"
    )
    install(FILES "$<TARGET_PDB_FILE:${Library}>"
        DESTINATION ${CMAKE_INSTALL_BINDIR} OPTIONAL
    )
    install(TARGETS ${Library} RUNTIME_DEPENDENCY_SET ${Library}_DepsSet)

    set(DepsDirectories "$<TARGET_FILE_DIR:${Library}>")

    foreach(Dependency IN LISTS ${Library}_Deps)
        list(APPEND DepsDirectories "$<TARGET_FILE_DIR:${Dependency}>")
    endforeach()

    # TODO: Figure out a way to gather directories ??$<TARGET_FILE_DIR:target>
    install(RUNTIME_DEPENDENCY_SET ${Library}_DepsSet
        PRE_EXCLUDE_REGEXES "api-ms-" "ext-ms-" ${CopyInstallDeps}
        POST_EXCLUDE_REGEXES ".*system32/.*\\.dll"
        DIRECTORIES ${DepsDirectories}
    )

    if(WIN32)
        set(SharedDestination "${CMAKE_INSTALL_BINDIR}")
    else()
        set(SharedDestination "${CMAKE_INSTALL_LIBDIR}")
    endif()

    get_target_property(LibName ${Library} OUTPUT_NAME)

    if("${LibName}" STREQUAL "LibName-NOTFOUND")
        set(LibName "${Library}")
    endif()

    set(SharedLibs "")
    set(ImpLibs "")
    set(SharedLibsProp "")
    set(ImpLibsProp "")
    set(SharedNames "")

    # string(APPEND SharedLibs "\nset_and_check(DEPS_${Library}_LIBRARY \"\$\{PACKAGE_PREFIX_DIR\}/${SharedDestination}/")
    # string(APPEND SharedLibs "$<TARGET_FILE_PREFIX:${Library}>${LibName}_release$<TARGET_FILE_SUFFIX:${Library}>")
    # string(APPEND SharedLibs "\")")

    # if(WIN32)
    # string(APPEND ImpLibs "\nset_and_check(DEPS_${Library}_IMPLIB \"\$\{PACKAGE_PREFIX_DIR\}/${CMAKE_INSTALL_LIBDIR}/")
    # string(APPEND ImpLibs "${CMAKE_IMPORT_LIBRARY_PREFIX}${LibName}_release${CMAKE_IMPORT_LIBRARY_SUFFIX}")
    # string(APPEND ImpLibs "\")")

    # string(APPEND AllImpLibs "\n    IMPORTED_IMPLIB \"\$\{DEPS_${Library}_IMPLIB\}\" ")
    # endif()
    foreach(Config IN LISTS CONFIGURATIONS)
        string(TOUPPER "${Config}" PossibleConfigUpper)
        string(TOLOWER "${Config}" PossibleConfigLower)
        set(SharedFileName "$<TARGET_FILE_PREFIX:${Library}>${LibName}_${PossibleConfigLower}$<TARGET_FILE_SUFFIX:${Library}>")
        string(APPEND SharedLibs "\nset_and_check(DEPS_${Library}_LIBRARY_${PossibleConfigUpper} \"\$\{PACKAGE_PREFIX_DIR\}/${SharedDestination}/${SharedFileName}\")")
        string(APPEND SharedLibsProp "\n    IMPORTED_LOCATION_${PossibleConfigUpper} \"\$\{DEPS_${Library}_LIBRARY_${PossibleConfigUpper}\}\" ")

        if(WIN32)
            set(SharedImpFileName "${CMAKE_IMPORT_LIBRARY_PREFIX}${LibName}_${PossibleConfigLower}${CMAKE_IMPORT_LIBRARY_SUFFIX}")
            string(APPEND ImpLibs "\nset_and_check(DEPS_${Library}_IMPLIB_${PossibleConfigUpper} \"\$\{PACKAGE_PREFIX_DIR\}/${CMAKE_INSTALL_LIBDIR}/${SharedImpFileName}\")")
            string(APPEND ImpLibsProp "\n    IMPORTED_IMPLIB_${PossibleConfigUpper} \"\$\{DEPS_${Library}_IMPLIB_${PossibleConfigUpper}\}\" ")

            list(APPEND SharedNames "${SharedImpFileName}")
        endif()

        list(APPEND SharedNames "${SharedFileName}")
    endforeach()

    extract_properties_genex("${Library}" SharedProps PROPERTIES
        INTERFACE_COMPILE_DEFINITIONS
        INTERFACE_COMPILE_FEATURES
        INTERFACE_COMPILE_OPTIONS
        INTERFACE_LINK_OPTIONS
    )

    set(LibraryDepsInclude "")
    set(LibraryDeps "")
    set(LibraryDepsNames "")

    if(NOT "${${Library}_Deps}" STREQUAL "")
        set(LibraryDepsInclude "\n")

        foreach(Dependency IN LISTS ${Library}_Deps)
            string(APPEND LibraryDepsInclude "include(\$\{PACKAGE_PREFIX_DIR\}/cmake/Shared${Dependency}Target.cmake)\n")
            string(JOIN " " LibraryDepsNames "${LibraryDepsNames}" "\$\{DEPS_${Dependency}_FILENAMES\}")
        endforeach()

        set(CopyLinkDeps "${${Library}_Deps}")
        list(TRANSFORM CopyLinkDeps PREPEND "DEPS_")
        set(LibraryDeps "\n    INTERFACE_LINK_LIBRARIES \"${CopyLinkDeps}\"")
    endif()

    get_target_property(IsNoSoName ${Library} NO_SONAME)

    # IMPORTED_SONAME libname.soversion???
    # Version???
    # $<TARGET_SONAME_FILE_NAME:tgt>?
    # OUTPUT_NAME is SONAME in SDL2???
    # ?? IMPORTED_NO_SONAME ??
    # IMPORTED_LOCATION \"\$\{DEPS_${Library}_LIBRARY\}\" ${AllSharedLibs} ${AllImpLibs} ${SharedProps}
    set(LibInstall "${LibraryDepsInclude} ${SharedLibs} ${ImpLibs}

add_library(DEPS_${Library} SHARED IMPORTED)

set_target_properties(DEPS_${Library} PROPERTIES ${SharedLibsProp} ${ImpLibsProp} ${SharedProps} 
    IMPORTED_CONFIGURATIONS \"${ConfigsUpper}\" ${LibraryDeps}
    FOLDER \"${EXPORT_NAME}\" 
)

set(DEPS_${Library}_FILENAMES \"${SharedNames}\")
list(APPEND DEPS_${Library}_FILENAMES ${LibraryDepsNames})
")

    file(GENERATE OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Shared${Library}Target.cmake CONTENT "${LibInstall}")

    if(EXISTS ${CMAKE_CURRENT_BINARY_DIR}/Shared${Library}Target.cmake)
        install(FILES "${CMAKE_CURRENT_BINARY_DIR}/Shared${Library}Target.cmake"
            DESTINATION cmake
            CONFIGURATIONS Package
        )
    endif()
endforeach()

set_target_properties(${TargetBundleName} PROPERTIES
    ${ConfigUpper}_POSTFIX "_${ConfigLower}"
    COMPILE_PDB_OUTPUT_DIRECTORY "$<TARGET_FILE_DIR:${TargetBundleName}>"
    COMPILE_PDB_NAME_${ConfigUpper} "${TargetBundleName}_${ConfigLower}"
)

install(TARGETS ${TargetBundleName})

install(FILES "$<TARGET_FILE_DIR:${TargetBundleName}>/${TargetBundleName}_${ConfigLower}.pdb"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}" OPTIONAL
)

include(CMakePackageConfigHelpers)

set(TargetDepsInclude "")
set(TargetDeps "")
set(TargetDepsNames "")

if(NOT "${Wrapper_Deps}" STREQUAL "")
    set(TargetDepsInclude "\n")

    foreach(Dependency IN LISTS Wrapper_Deps)
        string(APPEND TargetDepsInclude "include(\$\{PACKAGE_PREFIX_DIR\}/cmake/Shared${Dependency}Target.cmake)\n")
        string(JOIN " " TargetDepsNames "${TargetDepsNames}" "\$\{DEPS_${Dependency}_FILENAMES\}")
    endforeach()

    set(CopyLinkDeps "${Wrapper_Deps}")
    list(TRANSFORM CopyLinkDeps PREPEND "DEPS_")
    list(APPEND CopyLinkDeps ${InstallDeps})
    set(TargetDeps "\n    INTERFACE_LINK_LIBRARIES \"${CopyLinkDeps}\"")
endif()

if("${TargetDeps}" STREQUAL "" AND NOT "${InstallDeps}" STREQUAL "")
    set(TargetDeps "\n    INTERFACE_LINK_LIBRARIES \"${InstallDeps}\"")
endif()

list(REMOVE_DUPLICATES InstallIncludeDirs)
list(FILTER InstallIncludeDirs EXCLUDE REGEX "^\\.\$")
set(InstallIncludeDirs ${InstallIncludeDirs})
list(TRANSFORM InstallIncludeDirs PREPEND "\$\{PACKAGE_PREFIX_DIR\}/include/")

set(INSTALL_INCLUDE_DIRS ${InstallIncludeDirs})

if("${INSTALL_INCLUDE_DIRS}" STREQUAL "")
    set(INSTALL_INCLUDE_DIRS "\$\{PACKAGE_PREFIX_DIR\}/include")
endif()

string(SUBSTRING "${INSTALL_INCLUDE_DIRS}" 22 -1 INSTALL_INCLUDE_DIRS)

set(AllLibraries "")
set(AllLocations "")
set(TargetNames "")

# string(APPEND AllLibraries "\nset_and_check(${EXPORT_NAME}_LIBRARY \"\$\{PACKAGE_PREFIX_DIR\}/lib/")
# string(APPEND AllLibraries "$<TARGET_FILE_PREFIX:${TargetBundleName}>${TargetBundleName}_release$<TARGET_FILE_SUFFIX:${TargetBundleName}>")
# string(APPEND AllLibraries "\")")
foreach(PossibleConfig IN LISTS CONFIGURATIONS)
    string(TOUPPER "${PossibleConfig}" PossibleConfigUpper)
    string(TOLOWER "${PossibleConfig}" PossibleConfigLower)

    set(TargetFileName "$<TARGET_FILE_PREFIX:${TargetBundleName}>${TargetBundleName}_${PossibleConfigLower}$<TARGET_FILE_SUFFIX:${TargetBundleName}>")
    string(APPEND AllLibraries "\nset_and_check(${EXPORT_NAME}_LIBRARY_${PossibleConfigUpper} \"\$\{PACKAGE_PREFIX_DIR\}/${CMAKE_INSTALL_LIBDIR}/${TargetFileName}\")")
    string(APPEND AllLocations "\n    IMPORTED_LOCATION_${PossibleConfigUpper} \"\$\{${EXPORT_NAME}_LIBRARY_${PossibleConfigUpper}\}\"")
    list(APPEND TargetNames "${TargetFileName}")
endforeach()

extract_properties_genex("${TARGET_TO_BUNDLE}" TargetProps PROPERTIES
    INTERFACE_COMPILE_DEFINITIONS
    INTERFACE_COMPILE_FEATURES
    INTERFACE_COMPILE_OPTIONS
    INTERFACE_LINK_OPTIONS
)

set(ExportAliasString "")

if(NOT "${TARGET_TO_BUNDLE}" STREQUAL "${EXPORT_NAME}")
    set(ExportAliasString "\nadd_library(${TARGET_TO_BUNDLE} ALIAS ${EXPORT_NAME})")
endif()

# TODO: Think about the benefits of allowed genex inside INCLUDE_DIR,
# and if it needs to be removed
# IMPORTED_LOCATION \"\$\{${EXPORT_NAME}_LIBRARY\}\"
file(GENERATE OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/BundleConfig.cmake.in CONTENT
    "@PACKAGE_INIT@ 
${TargetDepsInclude}
set(${EXPORT_NAME}_INCLUDE_DIRS \"@PACKAGE_INSTALL_INCLUDE_DIRS@\") ${AllLibraries}

set(${EXPORT_NAME}_FOUND TRUE)
add_library(${EXPORT_NAME} STATIC IMPORTED)

set_target_properties(${EXPORT_NAME} PROPERTIES ${AllLocations} ${TargetProps}
    INTERFACE_INCLUDE_DIRECTORIES \"\$\{${EXPORT_NAME}_INCLUDE_DIRS\}\" 
    IMPORTED_CONFIGURATIONS \"${ConfigsUpper}\" ${TargetDeps}
    FOLDER \"${EXPORT_NAME}\" 
)

check_required_components(${EXPORT_NAME})

set(${EXPORT_NAME}_BUNDLE_FILENAMES \"${TargetNames}\")
list(APPEND ${EXPORT_NAME}_BUNDLE_FILENAMES${TargetDepsNames}) ${ExportAliasString}
")

if(EXISTS ${CMAKE_CURRENT_BINARY_DIR}/BundleConfig.cmake.in)
    configure_package_config_file(${CMAKE_CURRENT_BINARY_DIR}/BundleConfig.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_NAME}Config.cmake
        INSTALL_DESTINATION cmake
        PATH_VARS INSTALL_INCLUDE_DIRS
    )
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_NAME}Config.cmake
        DESTINATION cmake
        CONFIGURATIONS Package
    )
endif()

get_target_property(TargetVersion ${TARGET_TO_BUNDLE} VERSION)

if("${TargetVersion}")
    write_basic_package_version_file("${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_NAME}ConfigVersion.cmake"
        VERSION ${TargetVersion}
        COMPATIBILITY AnyNewerVersion
    )
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_NAME}ConfigVersion.cmake
        DESTINATION cmake
        CONFIGURATIONS Package
    )
endif()