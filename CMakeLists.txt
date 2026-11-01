cmake_minimum_required(VERSION 3.16)
project(RoadFighterQML VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_standard_project_setup(REQUIRES 6.0)

qt_add_executable(roadfighter-qml
    main.cpp
)

qt_add_qml_module(roadfighter-qml
    URI RoadFighter
    VERSION 1.0
    QML_FILES
        Main.qml
        Car.qml
    RESOURCES
        assets/road_left.png
        assets/road_center.png
        assets/road_right.png
)

target_link_libraries(roadfighter-qml PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick
)
