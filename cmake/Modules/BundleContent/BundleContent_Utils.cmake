# bundle_static_library
# MIT License
#
# Copyright (c) 2019 Cristian Adam
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

function(bundle_static_library_new tgt_name bundled_tgt_name OutSharedLibs OutIncludeDirs)
    # TODO: MANUALLY_ADDED_DEPENDENCIES do, or do not
    set(StaticLibs "${tgt_name}")
    set(SharedLibs "")

    block(SCOPE_FOR VARIABLES PROPAGATE StaticLibs SharedLibs)

    macro(_recursively_collect_dependencies dependant input_target)
        set(_input_link_libraries LINK_LIBRARIES)

        get_target_property(_dependant_type ${dependant} TYPE)
        get_target_property(_input_type ${input_target} TYPE)

        if(${_input_type} STREQUAL "INTERFACE_LIBRARY")
            set(_input_link_libraries INTERFACE_LINK_LIBRARIES)
        endif()

        get_target_property(public_dependencies ${input_target} ${_input_link_libraries})

        foreach(dependency IN LISTS public_dependencies)
            if(TARGET "${dependency}")
                get_target_property(alias "${dependency}" ALIASED_TARGET)

                if(TARGET ${alias})
                    set(dependency "${alias}")
                endif()

                get_target_property(_type "${dependency}" TYPE)

                if("${_type}" STREQUAL "STATIC_LIBRARY" AND "${_dependant_type}" STREQUAL "STATIC_LIBRARY")
                    list(APPEND StaticLibs "${dependency}")
                elseif("${_type}" STREQUAL "SHARED_LIBRARY")
                    list(APPEND SharedLibs "${dependency}")
                    list(APPEND ${dependant}_Deps "${dependency}")
                endif()

                if(NOT _${tgt_name}_visited_${dependency})
                    set(_${tgt_name}_visited_${dependency} ON)

                    if("${_type}" STREQUAL "SHARED_LIBRARY")
                        _recursively_collect_dependencies("${dependency}" "${dependency}")
                    else()
                        _recursively_collect_dependencies("${dependant}" "${dependency}")
                    endif()
                endif()
            endif()
        endforeach()
    endmacro()

    _recursively_collect_dependencies("${tgt_name}" "${tgt_name}")

    set(AllLibs "")
    list(APPEND AllLibs ${tgt_name} ${SharedLibs})
    list(REMOVE_DUPLICATES AllLibs)

    foreach(Lib IN LISTS AllLibs)
        set(${Lib}_Deps "${${Lib}_Deps}" PARENT_SCOPE)
    endforeach()

    endblock()

    list(REMOVE_DUPLICATES StaticLibs)
    list(REMOVE_DUPLICATES SharedLibs)

    set(AllLibs "")
    list(APPEND AllLibs ${tgt_name} ${SharedLibs})
    list(REMOVE_DUPLICATES AllLibs)

    foreach(Lib IN LISTS AllLibs)
        message(NOTICE "Deps for ${Lib}: ${${Lib}_Deps}")
        set(${Lib}_Deps "${${Lib}_Deps}" PARENT_SCOPE)
    endforeach()

    set(LibDirectories "")
    block(SCOPE_FOR VARIABLES PROPAGATE LibDirectories)

    macro(_collect_public_dirs input_target)
        get_target_property(public_dependencies "${input_target}" INTERFACE_LINK_LIBRARIES)

        foreach(dependency IN LISTS public_dependencies)
            if(TARGET "${dependency}")
                get_target_property(alias "${dependency}" ALIASED_TARGET)

                if(TARGET ${alias})
                    set(dependency "${alias}")
                endif()

                get_target_property(Dirs "${dependency}" INTERFACE_INCLUDE_DIRECTORIES)

                if(NOT "${Dirs}" STREQUAL "Dirs-NOTFOUND")
                    list(APPEND LibDirectories "${Dirs}")
                endif()

                # message(NOTICE "----------INCLUDE----------")
                # message(NOTICE "${dependency}: ${Dirs}")
                # message(NOTICE "--------------------------")
                if(NOT _${tgt_name}_dir_visited_${dependency})
                    set(_${tgt_name}_dir_visited_${dependency} ON)
                    _collect_public_dirs("${dependency}")
                endif()
            endif()
        endforeach()
    endmacro()

    _collect_public_dirs("${tgt_name}")

    endblock()
    list(REMOVE_DUPLICATES LibDirectories)

    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/bundle_dummy.cpp "")
    add_library(${bundled_tgt_name} STATIC ${CMAKE_CURRENT_BINARY_DIR}/bundle_dummy.cpp)

    foreach(lib IN LISTS StaticLibs)
        target_sources(${bundled_tgt_name} PRIVATE $<TARGET_OBJECTS:${lib}>)
    endforeach()

    set(${OutSharedLibs} "${SharedLibs}" PARENT_SCOPE)
    set(${OutIncludeDirs} "${LibDirectories}" PARENT_SCOPE)
endfunction()

function(extract_properties_genex InTarget OutGenex)
    set(Options "")
    set(OneValueArgs "")
    set(MultiValueArgs "PROPERTIES")
    cmake_parse_arguments(PARSE_ARGV 2 args "${Options}" "${OneValueArgs}" "${MultiValueArgs}")

    set(PropertiesCond "")

    foreach(Prop ${args_PROPERTIES})
        set(PropGenex "$<TARGET_PROPERTY:${InTarget},${Prop}>")
        set(HasPropGenex "$<NOT:$<STREQUAL:${PropGenex},>>")
        set(TextGenex "$<IF:${HasPropGenex},\n    ${Prop} ${PropGenex} ,>")

        list(APPEND PropertiesCond "${TextGenex}")
    endforeach()

    string(REPLACE ";" "" PropertiesCond "${PropertiesCond}")
    set(${OutGenex} "${PropertiesCond}" PARENT_SCOPE)
endfunction()

if(NOT DEFINED EXECUTE_SEQUENTIAL_NEXT)
    set(EXECUTE_SEQUENTIAL_NEXT "<<")
endif()

# COMMANDS [<cmd> <list> <<]... COMMANDS_STOP [Forward other to execute_process]
function(execute_sequential)
    cmake_parse_arguments(PARSE_ARGV 0 ES_ARGS "COMMANDS_STOP" "" "COMMANDS")
    set(OutputQuiet OFF)
    set(QuotedArgs "")

    foreach(Arg IN LISTS ES_ARGS_UNPARSED_ARGUMENTS)
        string(APPEND QuotedArgs " [===[${Arg}]===]")

        if("${Arg}" MATCHES "^OUTPUT_QUIET\$")
            set(OutputQuiet "ON")
        endif()
    endforeach()

    function(_exe_seq_launch_process Cmd Args ForwardArgs Quiet)
        if("${Cmd}" STREQUAL "")
            return()
        endif()

        if(NOT ${Quiet})
            string(REPLACE ";" " " AccPrint "${Args}")
            message(STATUS "[ex_se] Executing command: ${Cmd} ${AccPrint}")
        endif()

        cmake_language(EVAL CODE "execute_process(COMMAND ${Cmd} ${Args} ${ForwardArgs})")
    endfunction()

    set(Cmd "")
    set(Accumulator "")

    foreach(Argument IN LISTS ES_ARGS_COMMANDS)
        if("${Cmd}" STREQUAL "")
            set(Cmd "${Argument}")
            continue()
        elseif(NOT "${Argument}" STREQUAL "${EXECUTE_SEQUENTIAL_NEXT}")
            list(APPEND Accumulator ${Argument})
            continue()
        endif()

        _exe_seq_launch_process("${Cmd}" "${Accumulator}" "${QuotedArgs}" ${OutputQuiet})
        set(Cmd "")
        set(Accumulator "")
    endforeach()

    _exe_seq_launch_process("${Cmd}" "${Accumulator}" "${QuotedArgs}" ${OutputQuiet})
endfunction()

function(_list_to_json_string InList OutString)
    string(REPLACE ";" "||" InList "${InList}")
    string(REPLACE "\"" "'" InList "${InList}")
    set(${OutString} ${InList} PARENT_SCOPE)
endfunction()

function(_json_string_to_list InString OutList)
    string(REPLACE "'" "\"" InString "${InString}")
    string(REPLACE "||" ";" InString "${InString}")
    set(${OutList} ${InString} PARENT_SCOPE)
endfunction()

macro(_set_if_undefined Variable Value)
    if(NOT DEFINED ${Variable})
        set(${Variable} ${Value})
    endif()
endmacro()

macro(_set_if_undefined_cache Variable Value DocString)
    if(NOT DEFINED ${Variable})
        set(${Variable} ${Value} CACHE INTERNAL "${DocString}")
    endif()
endmacro()

function(_make_valid_dir_name InString OutEscapedString)
    if("${InString}" STREQUAL "")
        message(FATAL_ERROR "Bundler: Directory name can't be empty")
    endif()

    string(REGEX REPLACE "[\\/:\\*?\"<>| ]+" "_" InString "${InString}")
    string(REGEX REPLACE "\\.$" "" InString "${InString}")

    set(${OutEscapedString} "${InString}" PARENT_SCOPE)
endfunction()
