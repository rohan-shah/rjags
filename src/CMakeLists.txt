cmake_minimum_required(VERSION 3.1)

#Construct R.lib if we're using Visual studio on Windows
if(${CMAKE_CXX_COMPILER_ID} STREQUAL MSVC)
	#R does not appear to tell us whether a debug build was selected, so just build a release build every time 
	message(STATUS "Checking that 64-bit R was selected")
	execute_process(COMMAND ${R_COMMAND} --no-restore --no-save -e "q()" OUTPUT_VARIABLE R_OUTPUT)
	string(FIND "${R_OUTPUT}" "64-bit" R_OUTPUT_64_BIT_INDEX)
	string(FIND "${R_OUTPUT}" "32-bit" R_OUTPUT_32_BIT_INDEX)
	if(NOT ${R_OUTPUT_32_BIT_INDEX} EQUAL -1)
		message(FATAL_ERROR "Checking that 64-bit R was selected - 32-bit R found")
	elseif(${R_OUTPUT_64_BIT_INDEX} EQUAL -1)
	 	message(STATUS ${R_OUTPUT})
		message(FATAL_ERROR "Checking that 64-bit R was selected - Unable to identify as either 64 or 32 bit")
	endif()
	message(STATUS "Checking that 64-bit R was selected - passed")

	message(STATUS "Checking that 64-bit compiler was selected")
	execute_process(COMMAND ${CMAKE_CXX_COMPILER} ERROR_VARIABLE COMPILER_OUTPUT_STRING OUTPUT_QUIET)
	string(FIND "${COMPILER_OUTPUT_STRING}" x86 COMPILER_OUTPUT_STRING_X86_INDEX)
	if(NOT ${COMPILER_OUTPUT_STRING_X86_INDEX} EQUAL -1)
		message(FATAL_ERROR "Checking that 64-bit compiler was selected - FAILED\nPlease ensure that you select the x64 developer tools prompt")
	endif()
	string(FIND "${COMPILER_OUTPUT_STRING}" "x64" COMPILER_OUTPUT_STRING_X64_INDEX)
	if(${COMPILER_OUTPUT_STRING_X64_INDEX} EQUAL -1)
		message(FATAL_ERROR "Checking that 64-bit compiler was selected - FAILED\nPlease ensure that you select the x64 developer tools prompt")
	endif()
	message(STATUS "Checking that 64-bit compiler was selected - passed")

	#If we're using MSVC, work out where lib.exe is
	get_filename_component(COMPILER_PATH "${CMAKE_CXX_COMPILER}" DIRECTORY CACHE)
	message(STATUS "Searching for lib.exe")
	find_program(LIB_EXECUTABLE lib PATHS ${COMPILER_PATH})
	if(${LIB_EXECUTABLE} STREQUAL LIB_EXECUTABLE-NOTFOUND)
		message(FATAL_ERROR "Searching for lib.exe - not found")
	else()
		message(STATUS "Searching for lib.exe - found")
	endif()

	#If we're using MSVC, work out where dumpbin.exe is
	message(STATUS "Searching for dumpbin.exe")
	find_program(DUMPBIN_EXECUTABLE dumpbin PATHS ${COMPILER_PATH})
	if(${DUMPBIN_EXECUTABLE} STREQUAL DUMPBIN_EXECUTABLE-NOTFOUND)
		message(FATAL_ERROR "Searching for dumpbin.exe - not found")
	else()
		message(STATUS "Searching for dumpbin.exe - found")
	endif()

	message(STATUS "Generating import library for R.dll")
	file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/R.def" "LIBRARY R\n")
	file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/R.def" "EXPORTS\n")
	execute_process(COMMAND "${DUMPBIN_EXECUTABLE}" /exports "${R_HOME}/bin/x64/R.dll" ERROR_QUIET OUTPUT_VARIABLE DUMPBIN_OUTPUT)
	#Strip off the junk at the start and end
	string(REGEX MATCHALL "[ |\t]+[0-9]+[ |\t]+[0-9A-F]+[ |\t]+0[0-9A-F]+[ |\t]+[^\n|\r]+\n" R_EXPORTS_LIST_UNFILTERED "${DUMPBIN_OUTPUT}")
	foreach(symbolline IN LISTS R_EXPORTS_LIST_UNFILTERED)
		string(REGEX REPLACE "[ |\t]+[0-9]+[ |\t]+[0-9A-F]+[ |\t]+0[0-9A-F]+[ |\t]+([^\n|\r]+)\n" "\t\\1" symbol "${symbolline}")
		file(APPEND "${CMAKE_CURRENT_BINARY_DIR}/R.def" "${symbol}\n")
	endforeach(symbolline)
	execute_process(COMMAND "${LIB_EXECUTABLE}" /MACHINE:X64 /nodefaultlib "/def:${CMAKE_CURRENT_BINARY_DIR}/R.def" "/out:${CMAKE_CURRENT_BINARY_DIR}/R.lib" ERROR_QUIET OUTPUT_QUIET)
	file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/R.def")
	if(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/R.lib")
		message(FATAL_ERROR "Generating import library for R.dll - Error R.lib not found")
	endif()
	message(STATUS "Generating import library for R.dll - done")

	if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.0")
		#Add a define to account for different name of certain function
		add_definitions(-Dsnprintf=_snprintf)
	endif()

	#Put a Makefile.win in the source directory
	find_program(FULL_MAKE_PROGRAM nmake)
	set(FULL_MAKE_PROGRAM "\"${FULL_MAKE_PROGRAM}\" /f ")
	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Makefile.in ${CMAKE_CURRENT_BINARY_DIR}/Makefile.win @ONLY)
endif()

#Make sure everything installed to the right place
set(CMAKE_INSTALL_PREFIX "${PROJECT_SOURCE_DIR}")

#Now add the shared libarry target
set(SourceFiles init.c jags.cc parallel.cc)

add_library(rJags SHARED ${SourceFiles} ${HeaderFiles} ${rJags_MOC_SOURCES})
target_link_libraries(rJags PRIVATE jags)
target_include_directories(rJags PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${R_INCLUDE_DIR})
if(APPLE)
	target_link_libraries(rJags PRIVATE ${R_LIBRARY})
	set_target_properties(rJags PROPERTIES SUFFIX ".so")
endif()
if(USE_OPENMP)
	find_package(OpenMP REQUIRED)
	target_compile_definitions(rJags PRIVATE USE_OPENMP)
endif()
target_compile_definitions(rJags PRIVATE CUSTOM_STATIC_RCPP)
set_property(TARGET rJags APPEND PROPERTY COMPILE_FLAGS ${OpenMP_CXX_FLAGS})
set_property(TARGET rJags APPEND PROPERTY LINK_FLAGS ${OpenMP_CXX_FLAGS})
set_property(TARGET rJags PROPERTY CXX_STANDARD 11)
set_property(TARGET rJags PROPERTY CXX_STANDARD_REQUIRED ON)

#The CXX_STANDARD doesn't seem to work for intel, so add this manually. 
if(CMAKE_CXX_COMPILER_ID MATCHES "Intel")
	target_compile_options(rJags PUBLIC "-std=c++11")
endif()
if(${CMAKE_CXX_COMPILER_ID} STREQUAL MSVC)
	#Add the /bigobj flag, which is required for builds involving debug information
	target_compile_options(rJags PUBLIC /bigobj)
endif()

#Ensure that it's installed to the right place
if(WIN32)
	if("${CMAKE_GENERATOR}" STREQUAL "NMake Makefiles")
		set_target_properties(rJags PROPERTIES RUNTIME_OUTUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}../src/ PDB_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/../src/)
	else()
		foreach(BUILD_TYPE IN LISTS CMAKE_CONFIGURATION_TYPES)
			string(TOUPPER ${BUILD_TYPE} UPPER_BUILD_TYPE)
			set_target_properties(rJags PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${UPPER_BUILD_TYPE} ${CMAKE_CURRENT_BINARY_DIR}/../${BUILD_TYPE}/src/ PDB_OUTPUT_DIRECTORY_${UPPER_BUILD_TYPE} ${CMAKE_CURRENT_BINARY_DIR}/../${BUILD_TYPE}/src/)
		endforeach()
	endif()
	target_link_libraries(rJags PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/R.lib)
	target_compile_definitions(rJags PUBLIC _CRT_SECURE_NO_WARNINGS)
endif()
