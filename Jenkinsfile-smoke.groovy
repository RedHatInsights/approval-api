/*
 * Requires: https://github.com/RedHatInsights/insights-pipeline-lib
 */

@Library("github.com/RedHatInsights/insights-pipeline-lib") _


if (env.CHANGE_ID) {
    runSmokeTest (
        ocDeployerBuilderPath: "approval",
        ocDeployerComponentPath: "approval",
        ocDeployerServiceSets: "approval",
        iqePlugins: ["iqe-approval-plugin"],
        pytestMarker: "approval-smoke",
    )
}
