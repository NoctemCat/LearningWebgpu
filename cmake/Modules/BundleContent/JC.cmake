
macro(_minus_one InNumber OutVar)
    math(EXPR ${OutVar} "${InNumber} - 1")
endmacro()

set(JC_Types "NULL;NUMBER;STRING;BOOLEAN;ARRAY;OBJECT")
set(JC_DefaultValueNULL "null")
set(JC_DefaultValueNUMBER "0")
set(JC_DefaultValueSTRING "")
set(JC_DefaultValueBOOLEAN "FALSE")
set(JC_DefaultValueARRAY "")
set(JC_DefaultValueOBJECT "")
set(JC_TrueValues "1;0;Y;N;TRUE;FALSE;ON;OFF;YES;NO")

macro(_JC_EnsureType VarPath)
    if(NOT DEFINED "${VarPath}_JCType" OR NOT "${${VarPath}_JCType}" IN_LIST JC_Types)
        message(WARNING "Not a JC Type ${VarPath}_JCType: ${${VarPath}_JCType}")
        return()
    endif()

    _JC_DeduceType(${VarPath} VarType)
    set(${VarPath}_JCType "${VarType}" PARENT_SCOPE)
endmacro()

macro(_JC_EnsureValidName VarName)
    if(NOT "${VarName}" MATCHES [=[[\w\./\-\+]+]=])
        message(FATAL_ERROR "Invalid variable name (\"${VarName}\") for literal reference syntax(CMP0053)")
    endif()
endmacro()

function(_JC_DeduceType VarPath OutVar)
    if(NOT DEFINED ${VarPath})
        message(STATUS "JC: ${VarPath} must be a defined target to deduce type")
        return()
    endif()

    if(DEFINED ${VarPath}_0)
        set(${OutVar} "ARRAY" PARENT_SCOPE)
        return()
    endif()

    foreach(VarMember IN LISTS ${VarPath})
        if(DEFINED ${VarPath}.${VarMember})
            set(${OutVar} "OBJECT" PARENT_SCOPE)
            return()
        endif()
    endforeach()

    if("${${VarPath}}" STREQUAL "null")
        set(${OutVar} "NULL" PARENT_SCOPE)
    elseif(NOT "${${VarPath}_JCType}" STREQUAL "STRING" AND "${${VarPath}}" MATCHES "^[0-9]+$")
        set(${OutVar} "NUMBER" PARENT_SCOPE)
    else()
        string(TOUPPER "${${VarPath}}" ValueUpper)
        if("${ValueUpper}" IN_LIST JC_TrueValues)
            set(${OutVar} "BOOLEAN" PARENT_SCOPE)
        elseif(DEFINED ${VarPath}_JCType)
            set(${OutVar} ${${VarPath}_JCType} PARENT_SCOPE)
        else()
            set(${OutVar} "STRING" PARENT_SCOPE)
        endif()
    endif()
endfunction()

macro(_JC_OutputJson_basic VarName Value)
    if(${Pretty})
        string(REPEAT " " ${CurrentDepth} Padding)
        string(APPEND Result "${Padding}")
    endif()

    if(NOT "${VarName}" STREQUAL "")
        string(APPEND Result "\"${VarName}\": ${Value}")
    else()
        string(APPEND Result "${Value}")
    endif()
endmacro()

macro(_JC_OutputJson_NULL VarPath VarName)
    _JC_OutputJson_basic("${VarName}" "null")
endmacro()

macro(_JC_OutputJson_NUMBER VarPath VarName)
    _JC_OutputJson_basic("${VarName}" "${${VarPath}}")
endmacro()

macro(_JC_OutputJson_STRING VarPath VarName)
    set(_JC_OutputString "${${VarPath}}")
    # if("${_JC_OutputString}" MATCHES "\"")
    #     set(_JC_OutputStringFound TRUE)
    #     message(NOTICE "Processing ${_JC_OutputString}")
    # endif()
    string(REPLACE "\"" "|'|" _JC_OutputString "${_JC_OutputString}")
    # if(${_JC_OutputStringFound})
    #     message(NOTICE "Replaced ${_JC_OutputString}")
    #     unset(_JC_OutputStringFound)
    # endif()
    _JC_OutputJson_basic("${VarName}" "\"${_JC_OutputString}\"")
    unset(_JC_OutputString)
endmacro()

macro(_JC_OutputJson_BOOLEAN VarPath VarName)
    if(${${VarPath}})
        _JC_OutputJson_basic("${VarName}" "true")
    else()
        _JC_OutputJson_basic("${VarName}" "false")
    endif()
endmacro()

macro(_JC_IncreaseDepth VarName AppendOpen)
    if(${Pretty})
        string(REPEAT " " ${CurrentDepth} Padding)
        math(EXPR CurrentDepth "${CurrentDepth} + ${Identation}")
        string(APPEND Result "${Padding}")
    endif()

    if(NOT "${VarName}" STREQUAL "")
        string(APPEND Result "\"${VarName}\": ")
    endif()

    string(APPEND Result "${AppendOpen}")
endmacro()

macro(_JC_DecreaseDepth AppendClose)
    if(${Pretty})
        math(EXPR CurrentDepth "${CurrentDepth} - ${Identation}")
        string(REPEAT " " ${CurrentDepth} Padding)
        string(APPEND Result "${Padding}")
    endif()

    string(APPEND Result "${AppendClose}")
endmacro()

function(_JC_OutputJson_ARRAY VarPath VarName)
    _JC_IncreaseDepth("${VarName}" "\[")

    if("${${VarPath}}" STREQUAL "")
        string(APPEND Result "\]")
        set(Result ${Result} PARENT_SCOPE)
        return()
    endif()

    if(${Pretty})
        string(APPEND Result "\n")
    endif()

    list(GET ${VarPath} -1 LastMember)

    foreach(Idx IN LISTS ${VarPath})
        _JC_EnsureType(${VarPath}_${Idx})
        cmake_language(CALL _JC_OutputJson_${${VarPath}_${Idx}_JCType} "${VarPath}_${Idx}" "")

        if(NOT "${Idx}" STREQUAL "${LastMember}")
            string(APPEND Result ",")
        endif()

        if(${Pretty})
            string(APPEND Result "\n")
        endif()
    endforeach()

    _JC_DecreaseDepth("\]")
    set(Result ${Result} PARENT_SCOPE)
endfunction()

function(_JC_OutputJson_OBJECT VarPath VarName)
    _JC_IncreaseDepth("${VarName}" "\{")

    if("${${VarPath}}" STREQUAL "")
        string(APPEND Result "\}")
        set(Result ${Result} PARENT_SCOPE)
        return()
    endif()

    if(${Pretty})
        string(APPEND Result "\n")
    endif()

    list(GET ${VarPath} -1 LastMember)

    foreach(Member IN LISTS ${VarPath})
        _JC_EnsureType(${VarPath}.${Member})
        cmake_language(CALL _JC_OutputJson_${${VarPath}.${Member}_JCType} "${VarPath}.${Member}" "${Member}")

        if(NOT "${Member}" STREQUAL "${LastMember}")
            string(APPEND Result ",")
        endif()

        if(${Pretty})
            string(APPEND Result "\n")
        endif()
    endforeach()

    _JC_DecreaseDepth("\}")
    set(Result ${Result} PARENT_SCOPE)
endfunction()

function(JC_OutputJson FromVar OutVar)
    cmake_parse_arguments(PARSE_ARGV 2 JC "PRETTY" "IDENTATION" "")

    if("${JC_IDENTATION}" STREQUAL "")
        set(JC_IDENTATION 2)
    endif()

    set(Identation ${JC_IDENTATION})
    set(Pretty ${JC_PRETTY})
    set(CurrentDepth 0)

    _JC_EnsureType(${FromVar})
    cmake_language(CALL _JC_OutputJson_${${FromVar}_JCType} ${FromVar} "")
    set(${OutVar} ${Result} PARENT_SCOPE)
endfunction()

macro(_JC_Parse_NULL InJson ParseToVariable)
    set(${ParseToVariable}_JCType "NULL" PARENT_SCOPE)
    set(${ParseToVariable} "null" PARENT_SCOPE)
endmacro()

macro(_JC_Parse_NUMBER InJson ParseToVariable)
    set(${ParseToVariable}_JCType "NUMBER" PARENT_SCOPE)
    set(${ParseToVariable} "${InJson}" PARENT_SCOPE)
endmacro()

macro(_JC_Parse_STRING InJson ParseToVariable)
    set(${ParseToVariable}_JCType "STRING" PARENT_SCOPE)
    string(REPLACE "|'|" "\"" _JC_Parse_STRING_Temp "${InJson}")
    set(${ParseToVariable} "${_JC_Parse_STRING_Temp}" PARENT_SCOPE)
    unset(_JC_Parse_STRING_Temp)
endmacro()

macro(_JC_Parse_BOOLEAN InJson ParseToVariable)
    set(${ParseToVariable}_JCType "BOOLEAN" PARENT_SCOPE)
    set(${ParseToVariable} "${InJson}" PARENT_SCOPE)
endmacro()

macro(_JC_Parse_ARRAY InJson ParseToVariable)
    set(${ParseToVariable}_JCType "ARRAY" PARENT_SCOPE)
    set(${ParseToVariable} "" PARENT_SCOPE)
    string(JSON OutLength ERROR_VARIABLE Err LENGTH "${InJson}")

    if(NOT "${Err}" STREQUAL "NOTFOUND")
        message(FATAL_ERROR "Error JC ${Err}: ${InJson}")
    endif()

    if(NOT "${OutLength}" EQUAL "0")
        _minus_one(${OutLength} OutLength)

        foreach(Idx RANGE ${OutLength})
            string(JSON MemberType TYPE "${InJson}" ${Idx})
            string(JSON MemberValue GET "${InJson}" ${Idx})

            _JC_EnsureValidName(${ParseToVariable}_${Idx})
            list(APPEND ${ParseToVariable} "${Idx}")

            string(REPLACE "\\u" "\\\\u" MemberValue "${MemberValue}")
            cmake_language(CALL _JC_Parse_${MemberType} "${MemberValue}" "${ParseToVariable}_${Idx}")
        endforeach()

        set(${ParseToVariable} "${${ParseToVariable}}" PARENT_SCOPE)
    endif()
endmacro()

macro(_JC_Parse_OBJECT InJson ParseToVariable)
    set(${ParseToVariable}_JCType "OBJECT" PARENT_SCOPE)
    set(${ParseToVariable} "" PARENT_SCOPE)

    string(JSON OutLength ERROR_VARIABLE Err LENGTH "${InJson}")

    if(NOT "${Err}" STREQUAL "NOTFOUND")
        message(FATAL_ERROR "Error JC ${Err}: ${InJson}")
    endif()

    if(NOT "${OutLength}" EQUAL "0")
        _minus_one(${OutLength} OutLength)

        # message(NOTICE " Debug Obejct Iter: ${ParseToVariable}, ${OutLength} ")
        foreach(Idx RANGE ${OutLength})
            # message(NOTICE " Debug Path: ${ParseToVariable}, ${MemberName} ")
            string(JSON VarName MEMBER "${InJson}" ${Idx})
            string(JSON MemberType TYPE "${InJson}" ${VarName})
            string(JSON MemberValue GET "${InJson}" ${VarName})

            _JC_EnsureValidName(${ParseToVariable}.${VarName})
            list(APPEND ${ParseToVariable} "${VarName}")

            # message(NOTICE "~~~${ParseToVariable}, ${MemberType}, ${${ParseToVariable}}, ${VarName}")
            string(REPLACE "\\u" "\\\\u" MemberValue "${MemberValue}")
            cmake_language(CALL _JC_Parse_${MemberType} "${MemberValue}" "${ParseToVariable}.${VarName}")
        endforeach()

        set(${ParseToVariable} "${${ParseToVariable}}" PARENT_SCOPE)
    endif()
endmacro()

function(JC_ParseJson InJson ParseToVariable)
    cmake_parse_arguments(PARSE_ARGV 2 JC "REPLACE_CHARS" "" "")
    string(JSON InJsonType ERROR_VARIABLE Err TYPE "${InJson}")

    if(NOT "${Err}" STREQUAL "NOTFOUND")
        message(FATAL_ERROR "Error JC ${Err}: ${InJson}")
    endif()

    set(ReplaceChars ${REPLACE_CHARS})
    cmake_language(CALL _JC_Parse_${InJsonType} "${InJson}" "${ParseToVariable}")
endfunction()

function(JC_CreateObject OutVar)
    set(TempObject "")
    set(Args "${ARGN}")
    list(REVERSE Args)

    while(Args)
        list(POP_BACK Args KeyName TypeOrValue)

        if("${TypeOrValue}" IN_LIST JC_Types)
            list(POP_BACK Args Value)
            set(ValueType ${TypeOrValue})
        else()
            _JC_DeduceType(TypeOrValue ValueType)
            set(Value ${TypeOrValue})
        endif()

        list(APPEND TempObject "${KeyName}")
        set(${OutVar}.${KeyName}_JCType "${ValueType}" PARENT_SCOPE)
        set(${OutVar}.${KeyName} "${Value}" PARENT_SCOPE)
    endwhile()

    if("${${OutVar}_JCType}" STREQUAL "OBJECT" AND NOT "${${OutVar}}" STREQUAL "")
        list(APPEND TempObject "${${OutVar}}")
    endif()

    set(${OutVar}_JCType "OBJECT" PARENT_SCOPE)
    set(${OutVar} "${TempObject}" PARENT_SCOPE)
endfunction()

function(JC_CreateArray OutVar)
    set(${OutVar}_JCType "ARRAY" PARENT_SCOPE)
    set(TempObject "")
    set(Args "${ARGN}")
    list(REVERSE Args)

    set(Idx 0)

    while(Args)
        list(POP_BACK Args TypeOrValue)

        if("${TypeOrValue}" IN_LIST JC_Types)
            list(POP_BACK Args Value)
            set(ValueType ${TypeOrValue})
        else()
            _JC_DeduceType(TypeOrValue ValueType)
            set(Value ${TypeOrValue})
        endif()

        list(APPEND TempObject "${Idx}")
        set(${OutVar}_${Idx}_JCType "${ValueType}" PARENT_SCOPE)
        set(${OutVar}_${Idx} "${Value}" PARENT_SCOPE)
        math(EXPR Idx "${Idx} + 1")
    endwhile()

    set(${OutVar} "${TempObject}" PARENT_SCOPE)
endfunction()

macro(_JC_DefaultValue JsonType OutVar)
    set(${OutVar} ${JC_DefaultValue${JsonType}})
endmacro()

macro(_JC_Assign_NULL FromVar ToVar)
    set(${ToVar}_JCType "${${FromVar}_JCType}" PARENT_SCOPE)
    set(${ToVar} "${${FromVar}}" PARENT_SCOPE)
endmacro()

macro(_JC_Assign_NUMBER FromVar ToVar)
    set(${ToVar}_JCType "${${FromVar}_JCType}" PARENT_SCOPE)
    set(${ToVar} "${${FromVar}}" PARENT_SCOPE)
endmacro()

macro(_JC_Assign_STRING FromVar ToVar)
    set(${ToVar}_JCType "${${FromVar}_JCType}" PARENT_SCOPE)
    set(${ToVar} "${${FromVar}}" PARENT_SCOPE)
endmacro()

macro(_JC_Assign_BOOLEAN FromVar ToVar)
    set(${ToVar}_JCType "${${FromVar}_JCType}" PARENT_SCOPE)
    set(${ToVar} "${${FromVar}}" PARENT_SCOPE)
endmacro()

macro(_JC_Assign_ARRAY FromVar ToVar)
    set(${ToVar}_JCType "${${FromVar}_JCType}" PARENT_SCOPE)
    set(${ToVar} "${${FromVar}}" PARENT_SCOPE)

    foreach(Idx IN LISTS ${FromVar})
        cmake_language(CALL _JC_Assign_${${FromVar}_${Idx}_JCType} "${FromVar}_${Idx}" "${ToVar}_${Idx}")
    endforeach()
endmacro()

macro(_JC_Assign_OBJECT FromVar ToVar)
    set(${ToVar}_JCType "${${FromVar}_JCType}" PARENT_SCOPE)
    set(${ToVar} "${${FromVar}}" PARENT_SCOPE)

    foreach(Member IN LISTS ${FromVar})
        cmake_language(CALL _JC_Assign_${${FromVar}.${Member}_JCType} "${FromVar}.${Member}" "${ToVar}.${Member}")
    endforeach()
endmacro()

function(JC_Assign FromVar ToVar)
    cmake_language(CALL _JC_Assign_${${FromVar}_JCType} "${FromVar}" "${ToVar}")
endfunction()

macro(JC_AssignParentScope FromVar ToVar)
    cmake_language(CALL _JC_Assign_${${FromVar}_JCType} "${FromVar}" "${ToVar}")
endmacro()
