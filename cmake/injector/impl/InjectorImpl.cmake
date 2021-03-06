SET(CMAKE_RESOURCE_INJECTOR_PREFIX "CMAKE_RESOURCE_INJECTOR_PREFIX")

INCLUDE(${CMAKE_CURRENT_LIST_DIR}/../compiler-dependent/GetASM.cmake)
INCLUDE(${CMAKE_CURRENT_LIST_DIR}/CodeGenerator.cmake)
INCLUDE(${CMAKE_CURRENT_LIST_DIR}/FileUtils.cmake)

ENABLE_LANGUAGE(ASM)
__RES_INJ_GET_ASM(GENERIC_ASM_FILE)

FUNCTION(__RES_INJ_TARGET_INJECT_CONSTEXPR_RESOURCE TARGET RES_NAME PATH)
    __RES_INJ_ASSERT_PATH(PATH)

    SET(PREFIX ${CMAKE_RESOURCE_INJECTOR_PREFIX}_TARGET_${TARGET})
    SET(SOURCE_PREFIX ${CMAKE_RESOURCE_INJECTOR_PREFIX})

    GET_PROPERTY(CURRENT_CODE_ENUM GLOBAL PROPERTY ${PREFIX}_CONSTEXPR_ENUM)
    GET_PROPERTY(CURRENT_CODE_USAGE GLOBAL PROPERTY ${PREFIX}_CONSTEXPR_ENUM_USAGE)

    __RES_INJ_READ_FILE(PATH TEXT)
    SET(NEW_ENUM "${RES_NAME}")
    __RES_INJ_NEW_CODE(ENUM_USAGE "\
        template <> inline                                                                         \n\
        consteval int ___compile_time_data_size<constinit_injected_resources::${RES_NAME}>() {     \n\
            return sizeof( \"${TEXT}\" );                                                          \n\
        }                                                                                          \n\
                                                                                                   \n\
        template <> inline                                                                         \n\
        consteval char const * ___compile_time_data<constinit_injected_resources::${RES_NAME}>() { \n\
            return \"${TEXT}\";                                                                    \n\
        }")

    __RES_INJ_APPEND_COMMA_SEP(CURRENT_CODE_ENUM NEW_ENUM)
    __RES_INJ_APPEND_CODE(CURRENT_CODE_USAGE ENUM_USAGE)

    SET_PROPERTY(GLOBAL PROPERTY ${PREFIX}_CONSTEXPR_ENUM "${CURRENT_CODE_ENUM}")
    SET_PROPERTY(GLOBAL PROPERTY ${PREFIX}_CONSTEXPR_ENUM_USAGE "${CURRENT_CODE_USAGE}")

    __RES_INJ_UPDATE_CODE_VAR(CONSTEXPR_ENUM CURRENT_CODE_ENUM)
    __RES_INJ_UPDATE_CODE_VAR(CONSTEXPR_ENUM_IMPLEMENTATION CURRENT_CODE_USAGE)

ENDFUNCTION()


FUNCTION(__RES_INJ_TARGET_INJECT_RESOURCE TARGET RES_NAME RES_PATH GENERATED_DIR)
    __RES_INJ_ASSERT_PATH(RES_PATH)
    EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} -E make_directory ${GENERATED_DIR})

    SET(PREFIX ${CMAKE_RESOURCE_INJECTOR_PREFIX}_TARGET_${TARGET})
    SET(SOURCE_PREFIX ${CMAKE_RESOURCE_INJECTOR_PREFIX})

    GET_PROPERTY(CURRENT_CODE_ENUM GLOBAL PROPERTY ${PREFIX}_ENUM)
    GET_PROPERTY(CURRENT_CODE_USAGE GLOBAL PROPERTY ${PREFIX}_ENUM_USAGE)

    SET(NEW_ENUM "${RES_NAME}")
    SET(RES_NAME ${SOURCE_PREFIX}_${RES_NAME})

    __RES_INJ_NEW_CODE(ENUM_USAGE "\
        template <> inline                                                               \n\
        int ___compile_time_data_size<injector::injected_resources::${NEW_ENUM}>() {     \n\
            extern const int ${RES_NAME}_size;                                           \n\
            return ${RES_NAME}_size;                                                     \n\
        }                                                                                \n\
                                                                                         \n\
        template <> inline                                                               \n\
        char const * ___compile_time_data<injector::injected_resources::${NEW_ENUM}>() { \n\
            extern const char ${RES_NAME}_data[];                                        \n\
            return ${RES_NAME}_data;                                                     \n\
        }")

    __RES_INJ_APPEND_COMMA_SEP(CURRENT_CODE_ENUM NEW_ENUM)
    __RES_INJ_APPEND_CODE(CURRENT_CODE_USAGE ENUM_USAGE)

    SET_PROPERTY(GLOBAL PROPERTY ${PREFIX}_ENUM "${CURRENT_CODE_ENUM}")
    SET_PROPERTY(GLOBAL PROPERTY ${PREFIX}_ENUM_USAGE "${CURRENT_CODE_USAGE}")

    __RES_INJ_UPDATE_CODE_VAR(ENUM CURRENT_CODE_ENUM)
    __RES_INJ_UPDATE_CODE_VAR(ENUM_IMPLEMENTATION CURRENT_CODE_USAGE)


    SET(GENERATED_PATH "${GENERATED_DIR}/${RES_NAME}.S")
    CONFIGURE_FILE(${GENERIC_ASM_FILE} ${GENERATED_PATH}.tmp)  # RES_NAME, RES_PATH

    ADD_CUSTOM_COMMAND(OUTPUT ${GENERATED_PATH}
            COMMAND ${CMAKE_COMMAND} -E copy ${GENERATED_PATH}.tmp ${GENERATED_PATH}
            COMMAND ${CMAKE_COMMAND} -E remove ${GENERATED_PATH}.tmp
            DEPENDS ${RES_PATH})

    TARGET_SOURCES(${TARGET} PUBLIC ${GENERATED_PATH})
ENDFUNCTION()