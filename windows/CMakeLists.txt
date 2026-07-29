cmake_minimum_required(VERSION 3.21)
project(TickerLens VERSION 1.6.6 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 Network Widgets)

qt_standard_project_setup(REQUIRES 6.5)

set(TICKERLENS_SOURCES
    src/main.cpp
    src/AppSettings.cpp
    src/PlatformUtils.cpp
    src/UpdateInstaller.cpp
    src/win_main.cpp
    resources.qrc
)

# Embed .ico into the PE for Explorer / taskbar (when not tool-window)
if(WIN32)
    enable_language(RC)
    list(APPEND TICKERLENS_SOURCES assets/app.rc)
endif()

qt_add_executable(TickerLens ${TICKERLENS_SOURCES})

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
    # Custom WinMain in win_main.cpp — skip Qt EntryPoint which needs __argc
    target_compile_definitions(TickerLens PRIVATE QT_NO_ENTRYPOINT=1)
    target_link_libraries(TickerLens PRIVATE dwmapi shell32 gdi32)
    # windres needs to find app.ico next to app.rc
    set_source_files_properties(assets/app.rc PROPERTIES
        OBJECT_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/assets/app.ico"
    )
endif()

install(TARGETS TickerLens
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

# Ship DeepSeek helper next to binary for installers
install(FILES scripts/rate_news.py DESTINATION share/tickerlens)
