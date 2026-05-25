using Toybox.Application;
using Toybox.WatchUi;

class MyWatchFaceApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        // 标准写法，无需任何引入
        return [ new MyWatchFaceView() ];
    }
}