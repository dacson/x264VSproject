if(CMAKE_VERSION VERSION_LESS "2.8.10")
    find_program(HG_EXECUTABLE hg)
else()
    find_package(Hg QUIET)
endif()
find_package(Git QUIET) # present in 2.8.8

# defaults, in case everything below fails
set(X264_VERSION "unknown")
set(X264_LATEST_TAG "0.0")
set(X264_TAG_DISTANCE "0")

if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/../.hg_archival.txt)
    # read the lines of the archive summary file to extract the version
    file(READ ${CMAKE_CURRENT_SOURCE_DIR}/../.hg_archival.txt archive)
    STRING(REGEX REPLACE "\n" ";" archive "${archive}")
    foreach(f ${archive})
        string(FIND "${f}" ": " pos)
        string(SUBSTRING "${f}" 0 ${pos} key)
        string(SUBSTRING "${f}" ${pos} -1 value)
        string(SUBSTRING "${value}" 2 -1 value)
        set(hg_${key} ${value})
    endforeach()
    if(DEFINED hg_tag)
        set(X264_VERSION ${hg_tag})
        set(X264_LATEST_TAG ${hg_tag})
        set(X264_TAG_DISTANCE "0")
    elseif(DEFINED hg_node)
        string(SUBSTRING "${hg_node}" 0 16 hg_id)
        set(X264_VERSION "${hg_latesttag}+${hg_latesttagdistance}-${hg_id}")
    endif()
elseif(HG_EXECUTABLE AND EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/../.hg)
    if(EXISTS "${HG_EXECUTABLE}.bat")
        # mercurial source installs on Windows require .bat extension
        set(HG_EXECUTABLE "${HG_EXECUTABLE}.bat")
    endif()
    message(STATUS "hg found at ${HG_EXECUTABLE}")

    execute_process(COMMAND
        ${HG_EXECUTABLE} log -r. --template "{latesttag}"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE X264_LATEST_TAG
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    execute_process(COMMAND
        ${HG_EXECUTABLE} log -r. --template "{latesttagdistance}"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE X264_TAG_DISTANCE
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    execute_process(
        COMMAND
        ${HG_EXECUTABLE} log -r. --template "{node}"
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE X264_REVISION_ID
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    string(SUBSTRING "${X264_REVISION_ID}" 0 12 X264_REVISION_ID)

    if(X264_LATEST_TAG MATCHES "^r")
        string(SUBSTRING ${X264_LATEST_TAG} 1 -1 X264_LATEST_TAG)
    endif()
elseif(GIT_EXECUTABLE AND EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/../.git)
    execute_process(
        COMMAND
        ${GIT_EXECUTABLE} rev-list --tags --max-count=1
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE X264_LATEST_TAG_COMMIT
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    execute_process(
        COMMAND
        ${GIT_EXECUTABLE} describe --tags ${X264_LATEST_TAG_COMMIT}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE X264_LATEST_TAG
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    execute_process(
        COMMAND
        ${GIT_EXECUTABLE} rev-list ${X264_LATEST_TAG}.. --count --first-parent
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE X264_TAG_DISTANCE
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    execute_process(
        COMMAND
        ${GIT_EXECUTABLE} log -1 --format=g%h
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE X264_REVISION_ID
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
endif()
if(X264_TAG_DISTANCE STREQUAL "0")
    set(X264_VERSION "${X264_LATEST_TAG}")
else()
    set(X264_VERSION "${X264_LATEST_TAG}+${X264_TAG_DISTANCE}-${X264_REVISION_ID}")
endif()

message(STATUS "x264 version ${X264_VERSION}")
