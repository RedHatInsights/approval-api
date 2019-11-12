/*
 * Requires: https://github.com/RedHatInsights/insights-pipeline-lib
 */

@Library("github.com/RedHatInsights/insights-pipeline-lib@v3") _


if (env.CHANGE_ID) {
    execSmokeTest (
        ocDeployerBuilderPath: "approval/approval-api",
        ocDeployerComponentPath: "approval/approval-api",
        ocDeployerServiceSets: "approval,platform-mq",
        iqePlugins: ["iqe-approval-plugin"],
        pytestMarker: "approval_api_smoke",
    )
}
