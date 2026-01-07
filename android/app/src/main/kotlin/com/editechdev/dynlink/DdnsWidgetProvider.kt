package com.editechdev.dynlink

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class DdnsWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val ip = widgetData.getString("ip", "---.---.---.---")
            val domain = widgetData.getString("domain", "Tap to Configure")
            val status = widgetData.getString("status", "Idle")
            val lastUpdated = widgetData.getString("last_updated", "")

            views.setTextViewText(R.id.widget_ip, ip)
            views.setTextViewText(R.id.widget_domain, domain)
            views.setTextViewText(R.id.widget_status, status)
            views.setTextViewText(R.id.widget_last_updated, lastUpdated)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
