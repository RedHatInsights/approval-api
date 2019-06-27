/*
 * Requires: https://github.com/RedHatInsights/insights-pipeline-lib
 */

@Library("github.com/RedHatInsights/insights-pipeline-lib") _


if (env.CHANGE_ID) {
    runSmokeTest (
        ocDeployerBuilderPath: "approval/approval-api",
        ocDeployerComponentPath: "approval/approval-api",
        ocDeployerServiceSets: "approval,platform-mq",
        iqePlugins: ["iqe-approval-plugin"],
        pytestMarker: "approval-api-smoke",
    )
}
