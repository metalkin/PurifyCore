cmake_policy(SET CMP0007 NEW)

function(get_folder_name IN_DIR OUT_NAME)
	string(REPLACE "/" ";" p2list "${IN_DIR}")
	list(REVERSE p2list)
	list(GET p2list 0 temp)
	set(${OUT_NAME} "${temp}" PARENT_SCOPE)
endfunction(get_folder_name OUT_NAME)

function(findKeywordIndex IN_LIST IN_KEYWORD OUT_INDEX)
	foreach(LIST_ITEM ${IN_LIST})
		if(LIST_ITEM MATCHES "${IN_KEYWORD}")
			list(FIND IN_LIST ${LIST_ITEM} LIST_INDEX)
			set(${OUT_INDEX} "${LIST_INDEX}" PARENT_SCOPE)
			return()
		endif()
	endforeach()
	set(${OUT_INDEX} "-1" PARENT_SCOPE)
endfunction(findKeywordIndex OUT_INDEX)

#message("solution dir: ${slnDir}")

if(slnDir)
	set(srcDir ${slnDir})
else()
	set(srcDir ${CMAKE_SOURCE_DIR})
endif()
get_folder_name(${srcDir} SOLUTION_NAME)
#message("I am in ${srcDir} for ${SOLUTION_NAME}")
file(GLOB solution ${srcDir}/Build/${SOLUTION_NAME}.sln)
file(GLOB allBuildProjs ${srcDir}/Build/ALL_BUILD.vcxproj*)
if ("${allBuildProjs}")
	file(REMOVE ${allBuildProjs})
endif()
file(READ ${solution} solutionText)
STRING(REGEX REPLACE "\n" ";" solutionTextList "${solutionText}")
findKeywordIndex("${solutionTextList}" "(.*)ALL_BUILD" startIndex)
findKeywordIndex("${solutionTextList}" "EndProject" endIndex)
if (NOT "${startIndex}" STREQUAL "-1" AND NOT "${endIndex}" STREQUAL "-1")
	#message("solution: ${SOLUTION_NAME} at ${startIndex} ${endIndex}")
	foreach(loop_var RANGE ${startIndex} ${endIndex})
		list(REMOVE_AT solutionTextList ${startIndex})
	endforeach()
	list(REMOVE_AT solutionTextList ${startIndex})

	STRING(REGEX REPLACE ";" "\n" solutionText "${solutionTextList}")
	file(WRITE ${solution} "${solutionText}")
endif()
#message("allBuildProjs: ${allBuildProjs}")

#file(READ ${binDir}/protolist.stamp oldStamp)