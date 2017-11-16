cmake_minimum_required(VERSION 3.1)
project(rJags)

option(USE_OPENMP "Use OpenMP" OFF)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/src)
if(APPLE)
	find_library(R_LIBRARY R REQUIRED)
else()
	find_package(R REQUIRED)
endif()
find_package(jags REQUIRED)
find_package(bugs REQUIRED)
find_package(base REQUIRED)
set(CMAKE_SHARED_LIBRARY_PREFIX "")
add_subdirectory(src)
add_subdirectory(copyBinary)

add_custom_target(copyPackage ALL)
set(RFILES read.data.R mcarray.R jags.R jags.object.R dic.R)
if(WIN32)
	list(APPEND RFILES windows/zzz.R windows/progress.bar.R)
else()
	list(APPEND RFILES unix/zzz.R unix/progress.bar.R)
endif()
#Copy package to binary directory. This works differently on windows and linux
if(WIN32)
	if("${CMAKE_GENERATOR}" STREQUAL "NMake Makefiles")
		#Copy DESCRIPTION
		add_custom_command(TARGET copyPackage COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/DESCRIPTION" "${CMAKE_CURRENT_BINARY_DIR}/DESCRIPTION")
		#Copy R files
		foreach(RFILE IN LISTS RFILES)
			add_custom_command(TARGET copyPackage COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/R/${RFILE}" "${CMAKE_CURRENT_BINARY_DIR}/R/${RFILE}")
		endforeach()
		#Run roxygen2
		add_custom_command(TARGET copyPackage COMMAND "${R_COMMAND}" ARGS "-e \"library(roxygen2); roxygen2::roxygenise()\"" WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
	else()
		foreach(BUILD_TYPE IN LISTS CMAKE_CONFIGURATION_TYPES)
			#Copy DESCRIPTION
			add_custom_command(TARGET copyPackage COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/DESCRIPTION" "${CMAKE_CURRENT_BINARY_DIR}/${BUILD_TYPE}/DESCRIPTION")
			#Copy R files
			foreach(RFILE IN LISTS RFILES)
				add_custom_command(TARGET copyPackage COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/R/${RFILE}" "${CMAKE_CURRENT_BINARY_DIR}/${BUILD_TYPE}/R/${RFILE}")
			endforeach()
			#Run roxygen2
			add_custom_command(TARGET copyPackage COMMAND "${R_COMMAND}" ARGS "-e \"library(roxygen2); roxygen2::roxygenise()\"" WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${BUILD_TYPE}")
		endforeach()
	endif()
else()
	#Copy DESCRIPTION
	add_custom_command(TARGET copyPackage COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/DESCRIPTION" "${CMAKE_CURRENT_BINARY_DIR}/DESCRIPTION")
	#Copy R files
	foreach(RFILE IN LISTS RFILES)
		add_custom_command(TARGET copyPackage COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/R/${RFILE}" "${CMAKE_CURRENT_BINARY_DIR}/R/${RFILE}")
	endforeach()
	#Run roxygen2
	add_custom_command(TARGET copyPackage COMMAND "${R_COMMAND}" ARGS "-e" "\"library(roxygen2);roxygen2::roxygenise()\"" WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
endif()
if(WIN32)
	install(CODE "execute_process(COMMAND \"${R_COMMAND}\" CMD INSTALL --no-multiarch \$\{CMAKE_INSTALL_CONFIG_NAME\} WORKING_DIRECTORY \"${PROJECT_BINARY_DIR}\")")
else()
	install(CODE "execute_process(COMMAND \"${R_COMMAND}\" CMD INSTALL . WORKING_DIRECTORY \"${PROJECT_BINARY_DIR}\")")
endif()
