#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Road Fighter (QML)");
    QQmlApplicationEngine engine;
    // plain-qrc builds put Main.qml at :/Main.qml; qt_add_qml_module builds
    // place it under the module path. Try both.
    const QList<QUrl> candidates = {
        QUrl("qrc:/Main.qml"),
        QUrl("qrc:/RoadFighter/Main.qml"),
        QUrl("qrc:/qt/qml/RoadFighter/Main.qml"),
    };
    for (const QUrl &url : candidates) {
        engine.load(url);
        if (!engine.rootObjects().isEmpty())
            break;
    }
    if (engine.rootObjects().isEmpty())
        return 1;
    return app.exec();
}
