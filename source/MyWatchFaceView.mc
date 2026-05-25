using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.ActivityMonitor;

class MyWatchFaceView extends WatchUi.WatchFace {

    hidden const COLOR_ACCENT = 0x00BFFF;
    hidden const COLOR_DIM = 0x555555;
    hidden const COLOR_WARN = 0xFF4444;
    hidden const COLOR_OK = 0x44FF44;

    function initialize() {
        WatchFace.initialize();
    }

    // 安全获取心率 — 失败返回 null
    hidden function getHeartRate() {
        try {
            var iter = Toybox.SensorHistory.getHeartRateHistory({
                :period => 1,
                :order => Toybox.SensorHistory.ORDER_NEWEST_FIRST
            });
            if (iter != null) {
                var sample = iter.next();
                if (sample != null && sample has :data && sample.data != null) {
                    return sample.data;
                }
            }
        } catch (e) {
            // 模拟器或某些设备上没有心率传感器
        }
        return null;
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // 纯黑 AMOLED 背景
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // 时间
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var minute = clockTime.min;
        var second = clockTime.sec;

        // 日期
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var weekDaysCn = ["周日","周一","周二","周三","周四","周五","周六"];
        var dow = 1;
        if (info.day_of_week != null) {
            var rawDow = info.day_of_week;
            if (rawDow instanceof Lang.Number) {
                dow = rawDow;
            } else if (rawDow instanceof Lang.String) {
                // String -> Number
                var s = rawDow.toString();
                if (s.length() > 0) { dow = s.toNumber(); }
            }
        }
        if (dow > 7) { dow = 1; }
        var dateWeekStr = Lang.format("$1$月$2$日 $3$",
            [info.month.format("%d"), info.day.format("%d"),
             weekDaysCn[dow - 1]]);

        // 系统信息
        var stats = System.getSystemStats();
        var battery = stats.battery;
        var stepsInfo = ActivityMonitor.getInfo();
        var stepVal = 0;
        var goalVal = 10000;
        var calVal = 0;
        if (stepsInfo != null) {
            if (stepsInfo.steps != null) { stepVal = stepsInfo.steps; }
            if (stepsInfo.stepGoal != null && stepsInfo.stepGoal > 0) { goalVal = stepsInfo.stepGoal; }
            if (stepsInfo.calories != null) { calVal = stepsInfo.calories; }
        }

        // 心率
        var hr = getHeartRate();

        // ---- 绘制 ----

        // 顶部分割线
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_BLACK);
        dc.drawLine(cx - 140, 38, cx + 140, 38);

        // 日期（顶部）
        dc.setColor(0xAAAAAA, Graphics.COLOR_BLACK);
        dc.drawText(cx, 60, Graphics.FONT_TINY, dateWeekStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 主时间 HH:MM （用 FONT_LARGE 兼容所有设备）
        var timeStr = Lang.format("$1$:$2$", [hour.format("%02d"), minute.format("%02d")]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(cx, cy - 25, Graphics.FONT_LARGE, timeStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 秒数
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_BLACK);
        dc.drawText(cx + 72, cy - 62, Graphics.FONT_SMALL, second.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);

        // 底部分割线
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine(cx - 140, h - 88, cx + 140, h - 88);

        // ---- 底部三列信息 ----
        var colL = cx - 160;
        var colC = cx;
        var colR = cx + 160;

        // 步数
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_BLACK);
        dc.drawText(colL, h - 74, Graphics.FONT_TINY, "步数", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        var stepK = (stepVal.toFloat() / 1000.0).format("%.1f") + "k";
        dc.drawText(colL, h - 52, Graphics.FONT_SMALL, stepK, Graphics.TEXT_JUSTIFY_CENTER);

        // 心率
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_BLACK);
        dc.drawText(colC, h - 74, Graphics.FONT_TINY, "心率", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(colC, h - 52, Graphics.FONT_SMALL,
            (hr != null && (hr instanceof Number)) ? hr.format("%d") : "--", Graphics.TEXT_JUSTIFY_CENTER);

        // 电量
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_BLACK);
        dc.drawText(colR, h - 74, Graphics.FONT_TINY, "电量", Graphics.TEXT_JUSTIFY_CENTER);
        var batColor = COLOR_OK;
        if (battery < 20) { batColor = COLOR_WARN; }
        else if (battery < 40) { batColor = 0xFFAA00; }
        dc.setColor(batColor, Graphics.COLOR_BLACK);
        dc.drawText(colR, h - 52, Graphics.FONT_SMALL,
            battery.format("%d") + "%", Graphics.TEXT_JUSTIFY_CENTER);

        // ---- 步数进度条 ----
        var stepPct = ((stepVal.toFloat() / goalVal.toFloat()) * 100).toNumber();
        if (stepPct > 100) { stepPct = 100; }
        var barW = 240;
        var barH = 6;
        var barX = cx - barW / 2;
        var barY = h - 36;
        dc.setColor(COLOR_DIM, Graphics.COLOR_BLACK);
        dc.fillRectangle(barX, barY, barW, barH);
        dc.setColor(COLOR_ACCENT, Graphics.COLOR_BLACK);
        var fillW = (stepPct * barW / 100).toNumber();
        if (fillW < 1) { fillW = 1; }
        dc.fillRectangle(barX, barY, fillW, barH);

        // 热量
        dc.setColor(COLOR_DIM, Graphics.COLOR_BLACK);
        dc.drawText(cx, h - 20, Graphics.FONT_TINY,
            "热量 " + calVal.format("%d") + " kcal", Graphics.TEXT_JUSTIFY_CENTER);
    }
}