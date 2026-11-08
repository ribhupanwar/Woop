package com.noop.ui.forge

import com.noop.ui.DashboardCard
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WoopDashboardTrendTest {
    @Test fun trendDirectionDependsOnMetric() {
        assertEquals(WoopReferenceColors.healthGood, dashboardTrendColor(DashboardCard.HRV, 1))
        assertEquals(WoopReferenceColors.stressHigh, dashboardTrendColor(DashboardCard.HRV, -1))
        assertEquals(WoopReferenceColors.healthGood, dashboardTrendColor(DashboardCard.RESTING_HR, -1))
        assertEquals(WoopReferenceColors.stressHigh, dashboardTrendColor(DashboardCard.RESTING_HR, 1))
        assertNull(dashboardTrendColor(DashboardCard.CALORIES, 1))
        assertNull(dashboardTrendColor(DashboardCard.WEIGHT, -1))
        assertNull(dashboardTrendColor(DashboardCard.STEPS, 0))
    }
}
