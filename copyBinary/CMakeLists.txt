cmake_minimum_required(VERSION 3.1)
function(copyBinary buildType destination resultName)
	set(COPIED_BINARY_FILES)

	#Now for JAGS
	get_target_property(JAGS_LOCATION jags "LOCATION_${buildType}")
	get_filename_component(NAME_PART "${JAGS_LOCATION}" NAME_WE)
	if(EXISTS ${JAGS_LOCATION})
		add_custom_command(OUTPUT "${destination}/${NAME_PART}.dll" COMMAND ${CMAKE_COMMAND} ARGS -E copy "${JAGS_LOCATION}" "${destination}/${NAME_PART}.dll")
		list(APPEND COPIED_BINARY_FILES "${destination}/${NAME_PART}.dll")
	endif()

	#Now for base
	get_target_property(BASE_LOCATION base "LOCATION_${buildType}")
	get_filename_component(NAME_PART "${BASE_LOCATION}" NAME_WE)
	if(EXISTS ${BASE_LOCATION})
		add_custom_command(OUTPUT "${destination}/${NAME_PART}.dll" COMMAND ${CMAKE_COMMAND} ARGS -E copy "${BASE_LOCATION}" "${destination}/${NAME_PART}.dll")
		list(APPEND COPIED_BINARY_FILES "${destination}/${NAME_PART}.dll")
	endif()

	#Now for bugs
	get_target_property(BUGS_LOCATION bugs "LOCATION_${buildType}")
	get_filename_component(NAME_PART "${BUGS_LOCATION}" NAME_WE)
	if(EXISTS ${BUGS_LOCATION})
		add_custom_command(OUTPUT "${destination}/${NAME_PART}.dll" COMMAND ${CMAKE_COMMAND} ARGS -E copy "${BUGS_LOCATION}" "${destination}/${NAME_PART}.dll")
		list(APPEND COPIED_BINARY_FILES "${destination}/${NAME_PART}.dll")
	endif()

	#Now for libiomp5md.dll
	add_custom_command(OUTPUT "${destination}/libiomp5md.dll" COMMAND ${CMAKE_COMMAND} ARGS -E copy "${INTEL_ROOT}/redist/intel64_win/compiler/libiomp5md.dll" "${destination}/libiomp5md.dll")
	list(APPEND COPIED_BINARY_FILES "${destination}/libiomp5md.dll")

	set(${resultName} ${COPIED_BINARY_FILES} PARENT_SCOPE)
endfunction()
if(WIN32)
	#Copy files for the command line executables
	set(COPIED_BINARY_FILES)
	#If we're on windows, Start copying dlls
	set(BUILD_TYPES Release Debug RelWithDebInfo MinSizeRel)

	foreach(val RANGE 3)
		list(GET BUILD_TYPES ${val} BUILD_TYPE)
		list(GET BOOST_BUILD_TYPES ${val} BOOST_BUILD_TYPE)
	
		copyBinary("${BUILD_TYPE}" "${CMAKE_BINARY_DIR}/${BUILD_TYPE}/inst/libs/x64/" additionalBinaryFiles)
		list(APPEND COPIED_BINARY_FILES ${additionalBinaryFiles})
	endforeach()

	add_custom_target(copyBinary ALL DEPENDS ${COPIED_BINARY_FILES})
endif()