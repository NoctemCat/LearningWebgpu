# <cmd> COMMANDS <list> [WORKING_DIRECTORY <dir>] [OUTPUT_QUIET] [OUTPUT_COMMAND_QUIET] [COMMAND_ERROR_IS_FATAL <ANY|LAST>]
# function(execute_sequential shell)
# set(options COMMAND_ERROR_IS_FATAL ANY LAST OUTPUT_QUIET OUTPUT_COMMAND_QUIET)
# set(oneValueArgs WORKING_DIRECTORY)
# set(multiValueArgs COMMANDS)
# cmake_parse_arguments(PARSE_ARGV 1 args "${options}" "${oneValueArgs}" "${multiValueArgs}")
# set(exe_args "")

# if(args_COMMAND_ERROR_IS_FATAL AND args_ANY)
# set(exe_args COMMAND_ERROR_IS_FATAL ANY)
# elseif(args_COMMAND_ERROR_IS_FATAL AND args_LAST)
# set(exe_args COMMAND_ERROR_IS_FATAL LAST)
# endif()

# if(args_OUTPUT_QUIET)
# list(APPEND exe_args OUTPUT_QUIET)
# endif()

# foreach(shell_command IN LISTS args_COMMANDS)
# if(NOT args_OUTPUT_COMMAND_QUIET)
# message(STATUS "${shell}|> ${shell_command}")
# endif()

# execute_process(
# COMMAND ${shell} "${shell_command}"
# WORKING_DIRECTORY "${args_WORKING_DIRECTORY}"
# ${exe_args}
# )
# endforeach()
# endfunction()