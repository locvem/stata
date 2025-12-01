* Compute payroll total when need_fix==1 following specified component rules

* Grouping keys
local groupvars "code year"

* Collect all existing variables from a space-delimited list
program define collect_vars, rclass
    syntax , CANDIDATES(string)
    local vars ""
    foreach v of local candidates {
        capture confirm variable `v'
        if !_rc local vars "`vars' `v'"
    }
    return local varlist `vars'
end

* Replace each main variable (if present) with the group sum of its detail variables when missing
program define fill_from_detail
    syntax , DETAILS(string) MAIN(string) GROUP(string)

    collect_vars, candidates(`"`details'"')
    local dlist `r(varlist)'
    if "`dlist'" == "" exit

    tempvar rowtmp grptmp
    egen double `rowtmp' = rowtotal(`dlist')
    bysort `group': egen double `grptmp' = total(`rowtmp')

    foreach m of local main {
        capture confirm variable `m'
        if !_rc replace `m' = `grptmp' if missing(`m')
    }

    drop `rowtmp' `grptmp'
end

* ---------------- Step 1: fill main items from their "其中：" details ----------------

fill_from_detail , details("应付辞退福利其中： 辞退福利其中：") ///
    main("应付辞退福利 辞退福利") group(`groupvars')

fill_from_detail , details("应付短期薪酬其中： 短期薪酬其中： 短期薪酬（应付境外短期薪酬）其中： 短期薪酬（应付境内短期薪酬）其中：") ///
    main("应付短期薪酬 短期薪酬 短期薪酬（应付境外短期薪酬） 短期薪酬（应付境内短期薪酬）") group(`groupvars')

fill_from_detail , details("应付设定提存计划及设定受益计划其中： 设定提存计划及设定受益计划其中： 应付设定提存计划其中： 设定提存计划其中： 应付设定受益计划其中：") ///
    main("应付设定提存计划及设定受益计划 应付设定提存计划 设定提存计划 应付设定受益计划 应付设定受益计划净负债") group(`groupvars')

fill_from_detail , details("应付内退福利其中：") ///
    main("应付内退福利") group(`groupvars')

fill_from_detail , details("离职后福利（设定提存计划）其中： 离职后福利设定提存计划其中： 应付离职后福利其中：") ///
    main("离职后福利（设定提存计划） 离职后福利 离职后福利（设定受益计划净负债） 离职后福利设定提存计划 离职后福利（设定受益计划） 离职后福利：设定受益计划 应付离职后福利") group(`groupvars')

fill_from_detail , details("短期薪酬及其他长期职工福利其中： 短期薪酬和其他长期职工福利其中：") ///
    main("短期薪酬及其他长期职工福利 短期薪酬和其他长期职工福利") group(`groupvars')

fill_from_detail , details("应付长期薪酬其中：") ///
    main("应付长期薪酬") group(`groupvars')

fill_from_detail , details("社会保险费其中：") ///
    main("社会保险费") group(`groupvars')

fill_from_detail , details("薪酬其中： 薪酬XXXX其中：") ///
    main("薪酬") group(`groupvars')

* ---------------- Step 2: build the 合计 components list ----------------

local sumvars ""
foreach candidates in ///
    "应付短期薪酬 短期薪酬 短期薪酬（应付境外短期薪酬） 短期薪酬（应付境内短期薪酬）" ///
    "应付辞退福利 辞退福利" ///
    "应付设定提存计划及设定受益计划 应付设定提存计划 设定提存计划 应付设定受益计划 应付设定受益计划净负债" ///
    "应付内退福利" ///
    "其他" ///
    "其他短期福利" ///
    "离职后福利（设定提存计划） 离职后福利 离职后福利（设定受益计划净负债） 离职后福利设定提存计划 离职后福利（设定受益计划） 离职后福利：设定受益计划 应付离职后福利" ///
    "一年内到期的长期应付职工薪酬" ///
    "短期职工薪酬" ///
    "股份支付" ///
    "其他长期职工福利" ///
    "短期薪酬及其他长期职工福利 短期薪酬和其他长期职工福利" ///
    "应付长期薪酬" ///
    "其他退休福利" ///
    "补充退休福利" ///
    "应付补充离职后福利" ///
    "其他长期福利" ///
    "职工福利费" ///
    "社会保险费" ///
    "住房公积金" ///
    "因解除劳动关系给予的补偿" ///
    "工资、奖金、津贴和补贴 应付工资、奖金、津贴和补贴" ///
    "工会经费和职工教育经费 应付工会经费和职工教育经费" ///
    "薪酬" ///
    "内部退养福利 应付内部退养福利 应付内退费用 应付内退福利" ///
    "应付其他福利" {

    collect_vars, candidates(`"`candidates'"')
    local existing `r(varlist)'
    if "`existing'" != "" local sumvars "`sumvars' `existing'"
}

* ---------------- Step 3: compute 合计 for need_fix == 1 ----------------

capture confirm variable 合计
if _rc generate double 合计 = .

if "`sumvars'" != "" {
    egen double __row_total = rowtotal(`sumvars') if need_fix == 1
    bysort `groupvars': egen double __grp_total = total(__row_total)
    replace 合计 = __grp_total if need_fix == 1 & missing(合计)
    drop __row_total __grp_total
}

label variable 合计 "need_fix==1 计算的合计"
