cmake_minimum_required(VERSION 3.1)
function(copyBinary buildType destination resultName)
	set(COPIED_BINARY_FILES)

	#Now for JAGS
	get_target_property(JAGS_LOCATION jags "LOCATION_${buildType}")
	get_filename_component(NAME_PART "${JAGS_LOCATION}" NAME)
	if(EXISTS ${JAGS_LOCATION})
		add_custom_command(OUTPUT "${destination}/${NAME_PART}" COMMAND ${CMAKE_COMMAND} ARGS -E copy "${JAGS_LOCATION}" "${destination}/${NAME_PART}")
		list(APPEND COPIED_BINARY_FILES "${destination}/${NAME_PART}")
	endif()

	#Now for base
	get_target_property(BASE_LOCATION base "LOCATION_${buildType}")
	get_filename_component(NAME_PART "${BASE_LOCATION}" NAME)
	if(EXISTS ${BASE_LOCATION})
		add_custom_command(OUTPUT "${destination}/${NAME_PART}" COMMAND ${CMAKE_COMMAND} ARGS -E copy "${BASE_LOCATION}" "${destination}/${NAME_PART}")
		list(APPEND COPIED_BINARY_FILES "${destination}/${NAME_PART}")
	endif()

	#Now for bugs
	get_target_property(BUGS_LOCATION bugs "LOCATION_${buildType}")
	get_filename_component(NAME_PART "${BUGS_LOCATION}" NAME)
	if(EXISTS ${BUGS_LOCATION})
		add_custom_command(OUTPUT "${destination}/${NAME_PART}" COMMAND ${CMAKE_COMMAND} ARGS -E copy "${BUGS_LOCATION}" "${destination}/${NAME_PART}")
		list(APPEND COPIED_BINARY_FILES "${destination}/${NAME_PART}")
	endif()

	#Now for libiomp5md
	get_filename_component(NAME_PART "${MKL_IOMP5_LIBRARY}" NAME)
	add_custom_command(OUTPUT "${destination}/${NAME_PART}" COMMAND ${CMAKE_COMMAND} ARGS -E copy "${MKL_IOMP5_LIBRARY}" "${destination}/${NAME_PART}")
	list(APPEND COPIED_BINARY_FILES "${destination}/${NAME_PART}")

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
else()
	copyBinary("${BUILD_TYPE}" "${CMAKE_BINARY_DIR}/inst/libs/" additionalBinaryFiles)
	list(APPEND COPIED_BINARY_FILES ${additionalBinaryFiles})

	add_custom_target(copyBinary ALL DEPENDS ${COPIED_BINARY_FILES})
endif()
