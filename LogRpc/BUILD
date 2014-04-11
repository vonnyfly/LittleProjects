cc_library(
    name = "logservice",
    srcs = [
    "gen-cpp/log_constants.cpp",
    "gen-cpp/LogService.cpp",
    "gen-cpp/log_types.cpp",
    "cpp-impl/report.cpp",
    ],
    deps = [
        "//thirdparty/boost:boost_system",
        "//thirdparty/thrift:thrift",
    ],
    incs = [
        "../../thirdparty/thrift/include/",
    ],
  )
cc_binary(
    name = "client",
    srcs = [
      "cpp-impl/client.cpp",
    ],
    incs = [
        "../../thirdparty/thrift/include/",
    ],
    deps = [
        "//thirdparty/boost:boost_system",
        ":logservice",
    ],
)

