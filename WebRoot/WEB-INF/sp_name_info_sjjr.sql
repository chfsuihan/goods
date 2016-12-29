
CREATE PROCEDURE informix.sp_name_info_sjjr() returning int;
define ps_begin_date  DATETIME YEAR TO SECOND;
define li_errcode integer;
on exception
	set li_errcode
	return li_errcode;
end exception; 

set debug file to '/home/informix/sp_name_info_sjjr.txt';
trace on;
-----------------------------------------------------------------企业---------------------------------------------------------------------------------------------
--项目代码

create temp table temp_app_type (type_id varchar(10),type_name varchar(50))  with no log;
insert into temp_app_type(type_id,type_name) values('1','申办');
insert into temp_app_type(type_id,type_name) values('2','变更');
insert into temp_app_type(type_id,type_name) values('3','延期');
insert into temp_app_type(type_id,type_name) values('4','变更');
insert into temp_app_type(type_id,type_name) values('5','其它');
insert into temp_app_type(type_id,type_name) values('6','其它');
insert into temp_app_type(type_id,type_name) values('7','撤销');
insert into temp_app_type(type_id,type_name) values('8','转让');
insert into temp_app_type(type_id,type_name) values('9','转让');
--11?


--查询上一次抽取时间
select last_extract_time into ps_begin_date
from sgb_data_extract_log  where module_name = 'naming';

--查询企业申请案表
select app_no,check_name,accept_organ,check_date,accept_date,app_case_type,status_id
	 from etpsname@qrypermitsoc:name_app 
where accept_date >=ps_begin_date
-- and check_name_id is not null
into temp tmp_etps_app with no log;

create index tmp_app_no_idx on tmp_etps_app(app_no);

--查询办理日期最小的
select a.app_no,min(b.subscript_date) as subscription_date from tmp_etps_app a,etpsname@qrypermitsoc:name_opinion b
where a.app_no= b.app_no
group by 1
into temp temp2 with no log;

create index tmp_app_no2 on temp2(app_no);

select distinct a.app_no,b.staff_name,b.user_id,b.result,b.text_opnn from temp2 a,etpsname@qrypermitsoc:name_opinion b
where a.app_no = b.app_no and a.subscription_date = b.subscript_date
into temp temp3 with no log;

create index t_tmp3_app_no on temp3(app_no);

--查询申请表
select a.*,b.staff_name,b.user_id,b.result,b.text_opnn
 from tmp_etps_app a left join temp3 b
on a.app_no = b.app_no 
into temp tmp_etps with no log;

--查询申请案具体表
select a.*,b.result
 from tmp_etps_app a left join etpsname@qrypermitsoc:name_opinion b
on a.app_no = b.app_no where b.result='受理'
into temp tmp_jc_apply with no log;

--审核过的申请案
select a.*,b.result,b.user_id,b.staff_name,b.text_opnn
 from tmp_etps_app a left join etpsname@qrypermitsoc:name_opinion b
on a.app_no = b.app_no  where ( b.result='核准' or b.result='通过' or b.result='驳回')
into temp tmp_jc_audit with no log;


--JC_APPLICATION 添加企业
select app_no||'SHGSSH' as st_pid,
	'0720'||'SHGSSH'||app_no as st_apply_id,
	'SHGSSH' as st_src,
	app_no as st_src_pid,
	'0720' as st_item_id,
	'企业名称预先核准登记' as st_item_name,
	'SHGSSH' as st_org_id,
	'上海市工商行政管理局' as st_org_name,
	accept_organ as st_dept_name,
	check_name as st_pro_name,
	check_date as dt_do_time,
	staff_name as st_person_name,
	user_id as st_person_no,
	'' as st_person_duty,
	result as st_result,
	text_opnn as st_opinion,
	'' as st_days_type, 
	'' as nm_commitment_days,
	'' as nm_real_days,
	check_name as st_applicant_name,
	'法人' as ST_APPLICANT_TYPE,
	'' as ST_CONTACT,
	'' as ST_CONTACT_PHONE,
	'' as ST_CONTACT_MOBILE,
	'' as ST_CONTACT_EMAIL,
	'窗口提交' as  ST_APPLY_METHOD,
	'' as ST_APPLY_CONTENT,
	'' as dt_intime,--不详
	'' as st_ctct_prs_name,--不详
	'' as st_ctct_prs_phone,--不详
	'' as st_ctct_prs_mobile,--不详
	'' as ST_WEBAPP_PASS,
	accept_date as DT_CLCTDOCS_TIME,
	'' as ST_APPLY_DOC_NO,--不详
	'' as dt_end,--不详
	'' as dt_begin,--不详
	'' as ST_CONTACT_DOCU_TYPE,
	'' as ST_CONTACT_DOCU_NO
 from tmp_etps a
into temp tmp_etps_application with no log;



--JC_APPLY
select '0720'||'SHGSSH'||a.app_no as st_apply_id,
	'' as st_suid,
	a.app_no as ST_SRC_APPLY_ID,
	'SHGSSH' as st_src,
	'上海市工商行政管理局' as st_org_name,--不详
	'SHGSSH' as st_org_id,--不详
	'0720' as st_item_id,
	'企业名称预先核准登记' as st_item_name,
	check_name as st_pro_name,
	a.accept_organ as st_dept_name,
    d.type_name as st_apply_type, 
	c.name as st_region,
	'单部门' as st_type,
	a.accept_date as  dt_apply_time,
	a.check_date as dt_accept_time,
	'' as dt_unsertake_time,--不详
	'' as dt_audit_time,--不详
	'' as dt_approval_time,--不详
	'' as dt_finish_time,--不详
	'' as nm_law_days,
	'' as nm_days,
	'' st_is_public,
	a.status_id as st_status,
	'' as st_disp_status,--不详
	result as st_do_result,
	'' as st_yj,
	'' as st_huangp,
	'' as st_hongp,
	'' as st_dc,
	'' as st_exp,
	'' as st_cp,
	'' as st_rule_check,
	'' as dt_intime,
	a.app_no as st_project_id, 
	'' as st_apply_person,
	'' as st_reg_address, 
	'' as st_item_type, 
	'' as st_bl_node_name, 
	'' as ST_APP_TYPE,
	'' as st_sub_item_id, 
	'' as st_sub_item_name, 
	'' as st_applicant_docu_type, 
	'' as st_applicant_docu_no
from tmp_jc_apply a left join framework@commonsoc:organ_node c
on a.accept_organ = c.code left join temp_app_type d
on a.app_case_type = d.type_id
into temp tmp_etps_apply with no log;

--审核表
select app_no||'SHGSSH' as ST_PID,
'0720'||'SHGSSH'||app_no as st_apply_id,
'SHGSSH' as st_src,
app_no as ST_SRC_PID,
'0720' as st_item_id,
'企业名称预先核准登记' as st_item_name,
'SHGSSH' as st_org_id,
'上海市工商行政管理局' as st_org_name,
accept_organ as st_dept_name,
check_name as st_pro_name,
check_date as dt_do_time,
staff_name as st_person_name,
user_id as st_person_no,
'' as ST_PERSON_DUTY,

case when result in ('核准','通过') then '审核通过'
	 else '审核不通过' end as st_result,
	 
text_opnn as st_opinion,
'' as st_days_type, 
'' as nm_commitment_days,--TODO 5?
'' as nm_real_days,--TODO 5?
'' as dt_intime,
'' as dt_end,
'' as dt_begin
from tmp_jc_audit a
into temp tmp_etps_audit;

--决定环节
select app_no||'SHGSSH' as ST_PID,
'0720'||'SHGSSH'||app_no as st_apply_id,
'SHGSSH' as st_src,app_no,
'0720' as st_item_id,
'企业名称预先核准登记' as st_item_name,
'SHGSSH' as st_org_id,
'上海市工商行政管理局' as st_org_name,
accept_organ as st_dept_name,
check_name as st_pro_name, 
check_date as dt_do_time,
staff_name as st_person_name,
user_id as st_person_no,
'' as duty,

case when result in ('核准','通过') then '审核通过'
	 else '审核不通过' end as st_result,
	 
text_opnn as st_opinion,
'' as st_days_type,
'' as nm_commitment_days,
'' as nm_real_days,
'是' as ST_AUTHORIZE_RESULT,
'' as ST_UNAUTHORIZE_REASON,
'' as dt_intime,
'' as dt_end,
'' as dt_begin
from tmp_jc_audit a
into temp tmp_etps_authorize;
 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--申请表
INSERT INTO JC_APPLICATION
SELECT * FROM tmp_etps_application;

--具体表
insert into JC_APPLY
SELECT * FROM tmp_etps_apply;

--受理表
insert into JC_ACCEPT
select  st_pid,st_apply_id,st_src,st_src_pid,st_item_id,st_item_name,
st_org_id,st_org_name,st_dept_name,st_pro_name,dt_do_time,
b.st_person_name,b.st_person_no,b.st_person_duty,'受理','同意',
'','',1,'受理','',b.st_person_name,b.st_person_duty,'',st_src_pid as ST_ACCEPT_INFO_NO,'',
'','','','','','','','','',''
from tmp_etps_application b;

--审核表
insert into JC_AUDIT
select * from tmp_etps_audit;

--决定表
insert into JC_AUTHORIZE 
select * from tmp_etps_authorize;

--更新时间
update sgb_data_extract_log set last_extract_time =current where module_name = 'naming';

return 0;
end procedure;
GO
