cmake_minimum_required( VERSION 2.8 )
cmake_policy(SET CMP0054 NEW)

# function(create_source_group sourceGroupName relativeSourcePath sourceFiles)
#
#
#
function(create_source_group sourceGroupName relativeSourcePath sourceFiles)
	FOREACH(currentSourceFile ${ARGN})
		FILE(RELATIVE_PATH folder ${relativeSourcePath} ${currentSourceFile})
		get_filename_component(filename ${folder} NAME)
		string(REPLACE ${filename} "" folder ${folder})
		if(NOT folder STREQUAL "")
			string(REGEX REPLACE "/+$" "" folderlast ${folder})
			string(REPLACE "/" "\\" folderlast ${folderlast})
			SOURCE_GROUP("${sourceGroupName}\\${folderlast}" FILES ${currentSourceFile})
		endif(NOT folder STREQUAL "")
	ENDFOREACH(currentSourceFile ${ARGN})

	FOREACH(currentSourceFile ${sourceFiles})
		FILE(RELATIVE_PATH folder ${relativeSourcePath} ${currentSourceFile})
		get_filename_component(filename ${folder} NAME)
		string(REPLACE ${filename} "" folder ${folder})
		if(NOT folder STREQUAL "")
			string(REGEX REPLACE "/+$" "" folderlast ${folder})
			string(REPLACE "/" "\\" folderlast ${folderlast})
			SOURCE_GROUP("${sourceGroupName}\\${folderlast}" FILES ${currentSourceFile})
		endif(NOT folder STREQUAL "")
	ENDFOREACH(currentSourceFile ${sourceFiles})
endfunction(create_source_group)

# function(get_folder_name OUT_NAME)
#
#
#
function(get_folder_name IN_DIR OUT_NAME)
string(REPLACE "/" ";" p2list "${IN_DIR}")
list(REVERSE p2list)
list(GET p2list 0 temp)
set(${OUT_NAME} "${temp}" PARENT_SCOPE)
endfunction(get_folder_name OUT_NAME)

#
#
#
#
function(REMOVE_FILE_EXTENSION inFiles outFiles)
	foreach(currFile ${inFiles})
		GET_FILENAME_COMPONENT(filePath ${currFile} PATH)
		GET_FILENAME_COMPONENT(fileNameWithoutExtension ${currFile} NAME_WE)
		set(filePathWithoutExtension "${filePath}/${fileNameWithoutExtension}")
		list(APPEND newFiles ${filePathWithoutExtension})
	endforeach()
	SET(${outFiles} "${newFiles}" PARENT_SCOPE)
endfunction()

#
#
#
#
macro(get_WIN32_WINNT version)
	if (WIN32 AND CMAKE_SYSTEM_VERSION)
		set(ver ${CMAKE_SYSTEM_VERSION})
		string(REPLACE "." "" ver ${ver})
		string(REGEX REPLACE "([0-9])" "0\\1" ver ${ver})

		set(${version} "0x${ver}")
	endif()
endmacro()

#
#
#
function(UPDATE_RESOURCE_FILE inFile outFile)
	file(TIMESTAMP ${inFile} inStamp)
	file(TIMESTAMP ${outFile} outStamp)
	if(NOT "${inStamp}" STREQUAL "${outStamp}")
		configure_file(${inFile} ${outFile})
	endif()
endfunction()

#
#
#
macro(GeneratePrecompiledHeader)
		#----- Mark PRECOMPILED HEADER -----
		if( NOT ${${PROJECT_NAME}_PRECOMPILED_HEADER} STREQUAL "")
			#IF(MSVC)
				GET_FILENAME_COMPONENT(PRECOMPILED_HEADER_NAME ${${PROJECT_NAME}_PRECOMPILED_HEADER} NAME)
				GET_FILENAME_COMPONENT(PRECOMPILED_BASENAME ${PRECOMPILED_HEADER_NAME} NAME_WE)
				SET(PRECOMPILED_BINARY "${PRECOMPILED_BASENAME}-$(Configuration).pch")
				
				#list(APPEND USE_PRECOMPILED ${PRECOMPILED_HEADER_NAME})
				#list(APPEND FORCE_INCLUDE ${PRECOMPILED_HEADER_NAME})
				#list(APPEND PRECOMPILED_OUTPUT ${PRECOMPILED_BINARY})
			#ENDIF(MSVC)
		endif()

			#------ Generate header content first ------
		set(generatedHeaderContent "")
		# Inherit pch
		set(outCompileFlags "")
		if(NOT "${${PROJECT_NAME}_RECURSIVE_INCLUDES}" STREQUAL "")
			#(STATUS "Before: ${PROJECT_NAME}, includes ${includeProjs}")
				#forced_include_protected(${compileFlags} "${includeProjs}" generatedHeaderHeader)
				forced_include_public(compileFlags ${PROJECT_NAME}_RECURSIVE_INCLUDES generatedHeaderContent)
			#forced_include_recursive(outCompileFlags "${includeProjs}" generatedHeaderHeader)
			#message("After: ${generatedHeaderHeader}")
		else()
			forced_include_public(compileFlags "EMPTY" generatedHeaderContent)
			#forced_include_recursive(outCompileFlags "EMPTY" generatedHeaderHeader)
		endif()

		# Add user-defined precompiled header to generated precompiled header
		if(NOT ${PRECOMPILED_HEADER_NAME} STREQUAL "")
			string(CONCAT generatedHeaderContent ${generatedHeaderContent} "/* Pre-compiled header */\n")
			#message("project name: ${PROJECT_NAME},${PRECOMPILED_HEADER_NAME}\"")
			string(CONCAT generatedHeaderContent ${generatedHeaderContent} "\#include \"${PRECOMPILED_HEADER_NAME}\"\n")
		else()
			#string(CONCAT generatedHeaderHeader ${generatedHeaderContent} "/* ${PROJECT_NAME} does not contain pre-compiled header .pch.h */\n")
		endif()

		if(generatedHeaderContent)
			#------ Create Auto-Include Header ------
			#if( NOT ${PRECOMPILED_HEADER} STREQUAL "")
			set(generatedHeaderFullName "${${PROJECT_NAME}_BINARY_DIR}/${PROJECT_NAME}.generated.pch.h")
			if( NOT ${PROJECT_NAME}_CPP_SRC STREQUAL "" )
				set(generatedSourceFullName "${${PROJECT_NAME}_BINARY_DIR}/${PROJECT_NAME}.generated.pch.cpp")
			else()
				set(generatedSourceFullName "${${PROJECT_NAME}_BINARY_DIR}/${PROJECT_NAME}.generated.pch.c")
			endif()
			set(generatedHeaderHeader "")
			set(generatedSourceContent "")
			GET_FILENAME_COMPONENT(generatedHeaderName ${generatedHeaderFullName} NAME)
			set(generatedBinary "${PROJECT_NAME}-$(Configuration).generated.pch")
			set(usePrecompiled ${generatedHeaderName})
			set(forceInclude ${generatedHeaderName})
			set(precompiledOutputBinary ${generatedBinary})
			file(GLOB existingGeneratedHeaderFullName ${generatedHeaderFullName} )
			file(GLOB existingGeneratedSourceFullName ${generatedSourceFullName} )
			
			string(CONCAT generatedHeaderHeader ${generatedHeaderHeader} "/* GENERATED HEADER FILE. DO NOT EDIT. */\n\n")
			string(CONCAT generatedSourceContent ${generatedSourceContent} "/* GENERATED SOURCE FILE. DO NOT EDIT. */ \n\#include \"${generatedHeaderName}\"")
			
			# Add export api.h
			if( ("${${PROJECT_NAME}_MODE}" STREQUAL "CONSOLE") OR ("${${PROJECT_NAME}_MODE}" STREQUAL "WIN32") )
			else()
				string(CONCAT generatedHeaderHeader ${generatedHeaderHeader} "/* Symbol Export API */\n#include \"${PROJECT_NAME}_API.generated.h\"\n\n")
			endif()
			
			string(CONCAT generatedHeaderContent ${generatedHeaderHeader} ${generatedHeaderContent})

			if(NOT existingGeneratedHeaderFullName STREQUAL "" AND NOT existingGeneratedSourceFullName STREQUAL "")
				file(READ ${existingGeneratedHeaderFullName} existingGeneratedHeaderContent)
				if(NOT ${existingGeneratedHeaderContent} STREQUAL ${generatedHeaderContent})
					file(WRITE ${existingGeneratedHeaderFullName} ${generatedHeaderContent})
				endif()
				file(READ ${existingGeneratedSourceFullName} existingGeneratedSourceContent)
				if(NOT ${existingGeneratedSourceContent} STREQUAL ${generatedSourceContent})
					file(WRITE ${existingGeneratedSourceFullName} ${generatedSourceContent})
				endif()
			else()
				file(WRITE ${generatedHeaderFullName} ${generatedHeaderContent})
				file(WRITE ${generatedSourceFullName} ${generatedSourceContent})
			endif()

			if(MSVC)
				SET_SOURCE_FILES_PROPERTIES(${${PROJECT_NAME}_SRC}
					PROPERTIES COMPILE_FLAGS
					"/Yu\"${generatedHeaderFullName}\"
					/FI\"${generatedHeaderFullName}\"
					/FI\"${${PROJECT_NAME}_PRIVATE_INCLUDE_FILES}\"
					/FI\"${${PROJECT_NAME}_PROTECTED_INCLUDE_FILES}\"
					/FI\"${${PROJECT_NAME}_PUBLIC_INCLUDE_FILES}\"
					/Fp\"${precompiledOutputBinary}\""
					OBJECT_DEPENDS "${precompiledOutputBinary}")

				if(NOT ${PROJECT_NAME}_CPP_SRC)
					set(COMPILER_LANGUAGE "/TC")
				endif()
				SET_SOURCE_FILES_PROPERTIES(${generatedSourceFullName}
					PROPERTIES COMPILE_FLAGS "${COMPILER_LANGUAGE} /Yc\"${generatedHeaderName}\" /Fp\"${generatedBinary}\""
					OBJECT_OUTPUTS "${generatedBinary}")
			endif()

			SOURCE_GROUP("Interface" FILES ${generatedHeaderFullName})
			SOURCE_GROUP("Interface" FILES ${generatedSourceFullName})
			list(APPEND ${PROJECT_NAME}_HEADERS ${generatedHeaderFullName})
			list(APPEND ${PROJECT_NAME}_SRC ${generatedSourceFullName})
		endif()
		

		##else( NOT ${PRECOMPILED_HEADER} STREQUAL "")
		##	file(WRITE "${${PROJECT_NAME}_BINARY_DIR}/${PROJECT_NAME}.generated.pub.h" )
		##endif()
		
endmacro()

MACRO(forced_include_public compileFlags includeProjs outString)
	set(outString2 "")
	if(NOT "${includeProjs}" STREQUAL "EMPTY")
		#message("${includeProjs} NOT EMPTY, FORCED INCLUDING")
		foreach(includeProj ${${includeProjs}})


			#forced_include_public_recursive(${compileFlags} ${includeProj} ${outString})
			list(APPEND ${PROJECT_NAME}_ALL_INCLUDE_DIRS ${${includeProj}_SOURCE_DIR_CACHED})
				
			# inherit build _BUILD_TYPE
			add_definitions("-D${${includeProj}_BUILD_TYPE}")

			#message("${includeProj}_PUBLIC_INCLUDE_FILES: ${${includeProj}_PUBLIC_INCLUDE_FILES}")
			if(NOT ${${includeProj}_PRECOMPILED_INCLUDE_FILES} STREQUAL ""
				OR NOT ${${includeProj}_PUBLIC_INCLUDE_FILES} STREQUAL ""
				OR "${${includeProj}_MODE}" STREQUAL "DYNAMIC" OR "${${includeProj}_MODE}" STREQUAL "SHARED"
				)
				string(CONCAT outString2 ${outString2} "/* ${includeProj}: */ \n")
			endif()

			if("${${includeProj}_MODE}" STREQUAL "DYNAMIC" OR "${${includeProj}_MODE}" STREQUAL "SHARED")
				string(CONCAT outString2 ${outString2} "\#include \"${includeProj}_API.generated.h\"\n")
			endif()

			if(NOT ${${includeProj}_PRECOMPILED_INCLUDE_FILES} STREQUAL "")
				foreach(pubFile ${${includeProj}_PRECOMPILED_INCLUDE_FILES})
					FILE(RELATIVE_PATH folder ${${includeProj}_SOURCE_DIR_CACHED} ${pubFile})
					#string(CONCAT ${outString} ${${outString}} "\#include \"${includeProj}_API.generated.h\"\n")
					string(CONCAT outString2 ${outString2} "\#include \"${folder}\"\n")
					if(MSVC)
						#string(CONCAT ${compileFlags} ${${compileFlags}} " " "/FI\"${folder}\"")
					endif()
				endforeach()
			endif()
			
			if(NOT ${${includeProj}_PUBLIC_INCLUDE_FILES} STREQUAL "")
				foreach(pubFile ${${includeProj}_PUBLIC_INCLUDE_FILES})
					FILE(RELATIVE_PATH folder ${${includeProj}_SOURCE_DIR_CACHED} ${pubFile})
					add_definitions("-D${includeProj}_PROJECT_ID=${${includeProj}_ID}")
					string(CONCAT outString2 ${outString2} "\#include \"${folder}\"\n")
					if(MSVC)
						#string(CONCAT ${compileFlags} ${${compileFlags}} " " "/FI\"${folder}\"")
					endif()
				endforeach()
			else()
				#string(CONCAT ${outString} ${${outString}} "/* Not found */\n")
			endif()

		endforeach()
	else()
		string(CONCAT outString2 ${outString2} "/* NO DEPENDENCY */\n\n")
	endif()

	if(outString2)
		string(CONCAT ${outString} ${${outString}} "/* Public Headers */\n")
		string(CONCAT ${outString} ${${outString}} ${outString2})
	else()

	endif()
	#string(CONCAT ${outString} ${${outString}} "\n")
ENDMACRO()

#
#
#
MACRO(forced_include_protected compileFlags includeProjs outString)
	string(CONCAT ${outString} ${${outString}} "\n/* Protected Headers */\n")
	if(NOT "${includeProjs}" STREQUAL "EMPTY")
		#message("${PROJECT_NAME} 1,${includeProjs},")
		FOREACH(includeProj ${includeProjs})
			if(NOT ${${includeProj}_PROTECTED_INCLUDE_FILES} STREQUAL "")
				string(CONCAT ${outString} ${${outString}} "/* ${includeProj}: */ \n")

				if(${${includeProj}_MODE} STREQUAL "DYNAMIC" OR ${${includeProj}_MODE} STREQUAL "SHARED")
					string(CONCAT ${outString} ${${outString}} "\#include \"${includeProj}_API.generated.h\"\n")
				endif()
				
				FOREACH(proFile ${${includeProj}_PROTECTED_INCLUDE_FILES})
					FILE(RELATIVE_PATH folder ${${includeProj}_SOURCE_DIR_CACHED} ${proFile})
					string(CONCAT ${outString} ${${outString}} "\#include \"${folder}\"\n")
					if(MSVC)
						string(CONCAT ${compileFlags} ${${compileFlags}} " " "/FI\"${folder}\"")
					endif()
				ENDFOREACH()
			else()
				#string(CONCAT ${outString} ${${outString}} "/* Not found */\n")
			endif()
			#string(CONCAT ${outString} ${${outString}} "\n")
		ENDFOREACH()
	else()
	#message("${PROJECT_NAME} 2")
		string(CONCAT ${outString} ${${outString}} "\n/* NO DEPENDENCY */")
	endif()
	#string(CONCAT ${outString} ${${outString}} "\n")
ENDMACRO()



MACRO(forced_include_public_recursive compileFlags includeProj outString)
	list(APPEND ${PROJECT_NAME}_ALL_INCLUDE_DIRS ${${includeProj}_SOURCE_DIR_CACHED})
	
	# inherit build _BUILD_TYPE
	add_definitions("-D${${includeProj}_BUILD_TYPE}")

	# include dependency first
	foreach(subIncludeProj ${${includeProj}_INCLUDES})
		forced_include_public_recursive(${compileFlags} ${subIncludeProj} ${outString})
	endforeach()

	string(CONCAT ${outString} ${${outString}} "/* ${includeProj}: */ \n")

	if("${${includeProj}_MODE}" STREQUAL "DYNAMIC" OR "${${includeProj}_MODE}" STREQUAL "SHARED")
		string(CONCAT ${outString} ${${outString}} "\#include \"${includeProj}_API.generated.h\"\n")
	endif()

	if(NOT ${${includeProj}_PRECOMPILED_INCLUDE_FILES} STREQUAL "")
		foreach(pubFile ${${includeProj}_PRECOMPILED_INCLUDE_FILES})
			FILE(RELATIVE_PATH folder ${${includeProj}_SOURCE_DIR_CACHED} ${pubFile})
			#string(CONCAT ${outString} ${${outString}} "\#include \"${includeProj}_API.generated.h\"\n")
			string(CONCAT ${outString} ${${outString}} "\#include \"${folder}\"\n")
			if(MSVC)
				#string(CONCAT ${compileFlags} ${${compileFlags}} " " "/FI\"${folder}\"")
			endif()
		endforeach()
	endif()
	
	if(NOT ${${includeProj}_PUBLIC_INCLUDE_FILES} STREQUAL "")
		foreach(pubFile ${${includeProj}_PUBLIC_INCLUDE_FILES})
			FILE(RELATIVE_PATH folder ${${includeProj}_SOURCE_DIR_CACHED} ${pubFile})
			add_definitions("-D${includeProj}_PROJECT_ID=${${includeProj}_ID}")
			string(CONCAT ${outString} ${${outString}} "\#include \"${folder}\"\n")
			if(MSVC)
				#string(CONCAT ${compileFlags} ${${compileFlags}} " " "/FI\"${folder}\"")
			endif()
		endforeach()
	else()
		#string(CONCAT ${outString} ${${outString}} "/* Not found */\n")
	endif()

	#string(CONCAT ${outString} ${${outString}} "\n")
	#message("INCLUDES: ${${includeProj}_INCLUDES}")

ENDMACRO()

#[[
MACRO(traverse_project_includes includeProjs outProjects)

		message("Traversing projects: ${${includeProjs}}")
		message("Current ${outProjects}: ${${outProjects}}")

		foreach(includeProj ${${includeProjs}})
			message("including: ${includeProj}")
			#traverse_project_includes(${includeProjs} outPorjs)
			if(${outProjects})
				list(FIND ${outProjects} ${includeProj} index)
				if(index EQUAL -1)
					message("${includeProj} not in ${${outProjects}}. Appending.")
					list(APPEND ${outProjects} ${incudeProj})
				endif()
			endif()
		endforeach()

		message("Result: ${${outProjects}}")
ENDMACRO()
#]]

MACRO(forced_include_recursive compileFlags includeProjs outString)
	#if(includeProjs)
	#	set(outProjects "")
	#	message("Start traversing for ${PROJECT_NAME} with ${includeProjs}: ${outProjects}")
	#	traverse_project_includes(includeProjs outProjects)
	#endif()

	#message("called ${includeProjs}")
	list(REMOVE_DUPLICATES includeProjs)
	forced_include_protected(${compileFlags} "${includeProjs}" ${outString})
	forced_include_public(${compileFlags} "${includeProjs}" ${outString})
ENDMACRO()

MACRO(search_and_link_libraries libs)
	foreach(proj ${PROJECT_NAMES})
		#message("name: ${proj}")
	endforeach()
	foreach(lib ${libs})
		list(FIND PROJECT_NAMES ${lib} index)
		if(NOT index EQUAL -1)
			# we found a target
			#list(APPEND ${PROJECT_NAME}_ALL_INCLUDE_DIRS ${lib})
			if(${${lib}_MODE} STREQUAL "STATIC")
				#message("linking: ${lib}")
				target_link_libraries(${PROJECT_NAME} PUBLIC ${lib})
			endif()
			if(${${lib}_MODE} STREQUAL "DYNAMIC" OR ${${lib}_MODE} STREQUAL "SHARED")
				#message("linking: ${lib}")
				target_link_libraries(${PROJECT_NAME} PUBLIC ${lib})
			endif()
			#message("found target: -D${${lib}_BUILD_TYPE}")
			#add_definitions("-D${${lib}_BUILD_TYPE}")
		else()
			#message("couldn't find target: ${lib}")
			string(FIND ${lib} "." has_dot)
			if(NOT has_dot EQUAL -1)
				file(GLOB_RECURSE lib_dir "${CMAKE_SOURCE_DIR}/*${lib}")
				if(EXISTS ${lib_dir})
					target_link_libraries(${PROJECT_NAME} PUBLIC ${lib_dir})
				else()
					target_link_libraries(${PROJECT_NAME} PUBLIC ${lib})
					#message("library not found: ${lib}")
				endif()
			endif()
		endif()
	endforeach()
ENDMACRO()
#
#
#
macro(ScanSourceFiles)
		#file(GLOB ${PROJECT_NAME}_BATCH_SCRIPTS ${CMAKE_SOURCE_DIR}/*Generate*.bat)
		file(GLOB_RECURSE ${PROJECT_NAME}_SRC ${CMAKE_CURRENT_SOURCE_DIR}/*.cxx ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/*.cc ${CMAKE_CURRENT_SOURCE_DIR}/*.c++ ${CMAKE_CURRENT_SOURCE_DIR}/*.c)
		file(GLOB_RECURSE ${PROJECT_NAME}_CPP_SRC ${CMAKE_CURRENT_SOURCE_DIR}/*.cxx ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/*.cc ${CMAKE_CURRENT_SOURCE_DIR}/*.c++)
		file(GLOB_RECURSE ${PROJECT_NAME}_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h ${CMAKE_CURRENT_SOURCE_DIR}/*.hpp ${CMAKE_CURRENT_SOURCE_DIR}/*.inl)
		file(GLOB_RECURSE ${PROJECT_NAME}_PRECOMPILED_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/*.pch.h)
		
		file(GLOB_RECURSE ${PROJECT_NAME}_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.rc ${CMAKE_CURRENT_SOURCE_DIR}/*.r ${CMAKE_CURRENT_SOURCE_DIR}/*.resx)
		file(GLOB_RECURSE ${PROJECT_NAME}_PROTO ${CMAKE_CURRENT_SOURCE_DIR}/*.proto ${CMAKE_CURRENT_SOURCE_DIR}/*.capnp)
		file(GLOB_RECURSE ${PROJECT_NAME}_MISC ${CMAKE_CURRENT_SOURCE_DIR}/*.l ${CMAKE_CURRENT_SOURCE_DIR}/*.y)
		file(GLOB_RECURSE ${PROJECT_NAME}_CONFIG ${CMAKE_CURRENT_SOURCE_DIR}/*.ini)
		file(GLOB_RECURSE ${PROJECT_NAME}_SHADERS
			${CMAKE_CURRENT_SOURCE_DIR}/*.vert
			${CMAKE_CURRENT_SOURCE_DIR}/*.frag
			${CMAKE_CURRENT_SOURCE_DIR}/*.geom
			${CMAKE_CURRENT_SOURCE_DIR}/*.ctrl
			${CMAKE_CURRENT_SOURCE_DIR}/*.eval
			${CMAKE_CURRENT_SOURCE_DIR}/*.glsl)
		unset(${PROJECT_NAME}_SRC CACHE)
		unset(${PROJECT_NAME}_CPP_SRC CACHE)
		unset(${PROJECT_NAME}_HEADERS CACHE)
		set( ${PROJECT_NAME}_SRC "${${PROJECT_NAME}_SRC}" CACHE STRING "" )
		set( ${PROJECT_NAME}_CPP_SRC "${${PROJECT_NAME}_CPP_SRC}" CACHE STRING "" )
		set( ${PROJECT_NAME}_HEADERS "${${PROJECT_NAME}_HEADERS}" CACHE STRING "" )


		if( NOT ${PROJECT_NAME}_HEADERS STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_HEADERS})
		endif()
		if( NOT ${PROJECT_NAME}_SRC STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_SRC})
		endif()
		if( NOT ${PROJECT_NAME}_CPP_SRC STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_CPP_SRC})
		endif()

		if( NOT ${PROJECT_NAME}_RESOURCES STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_RESOURCES})
			foreach(RESOURCE ${${PROJECT_NAME}_RESOURCES})
				FILE(RELATIVE_PATH folder ${CMAKE_CURRENT_SOURCE_DIR} ${RESOURCE})
				string(FIND ${folder} "/" result)
				if(${result} STREQUAL "-1")
					SOURCE_GROUP("Resource Files" FILES ${${PROJECT_NAME}_RESOURCES})
				endif()
			endforeach()
		endif()

		LIST(APPEND ${PROJECT_NAME}_RESOURCES ${${PROJECT_NAME}_CONFIG})

		if( NOT ${PROJECT_NAME}_PROTO STREQUAL "" )
			SOURCE_GROUP("Proto Files" FILES ${${PROJECT_NAME}_PROTO})
		endif()

		if( NOT ${PROJECT_NAME}_CONFIG STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_CONFIG})
		endif()

		if( NOT ${PROJECT_NAME}_BATCH_SCRIPTS STREQUAL "" )
			SOURCE_GROUP("" FILES ${${PROJECT_NAME}_BATCH_SCRIPTS})
		endif()

		if( NOT ${PROJECT_NAME}_MISC STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_MISC})
		endif()

		LIST(APPEND ${PROJECT_NAME}_MISC ${${PROJECT_NAME}_PROTO})
		LIST(APPEND ${PROJECT_NAME}_MISC ${${PROJECT_NAME}_BATCH_SCRIPTS})

		if( (${PROJECT_NAME}_SRC STREQUAL "") AND (${PROJECT_NAME}_HEADERS STREQUAL "") )
			message(STATUS "Project is empty, a placeholder C header was created to set compiler language.")
			file(WRITE Placeholder.h "")
			LIST(APPEND ${PROJECT_NAME}_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/Placeholder.h)
			#message(FATAL_ERROR "Please insert at least one source file to use the CMakeLists.txt.")
		endif()


		if( NOT ${PROJECT_NAME}_SHADERS STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_SHADERS})
		endif()
endmacro()

#
#
#
macro(GetIncludeProjectsRecursive inString outString)
	foreach(proj ${${inString}_INCLUDES})
		GetIncludeProjectsRecursive(${proj} ${outString})
		list(APPEND ${outString} ${proj})
	endforeach()
endmacro()