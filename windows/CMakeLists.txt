cmake_minimum_required(VERSION 3.21)
project(TickerLens VERSION 1.5.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Network Widgets)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(TickerLens
    src/main.cpp
    src/AppSettings.cpp
    src/PlatformUtils.cpp
    resources.qrc
)

target_include_directories(TickerLens PRIVATE src)

target_link_libraries(TickerLens PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Widgets
)

# Windows: subsystem windows (no console) for release
if(WIN32)
    set_target_properties(TickerLens PROPERTIES
        WIN32_EXECUTABLE TRUE
        OUTPUT_NAME "TickerLens"
    )
endif()

install(TARGETS TickerLens
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

# Ship DeepSeek helper next to binary for installers
install(FILES scripts/rate_news.py DESTINATION share/tickerlens)
