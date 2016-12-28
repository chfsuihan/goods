
CREATE PROCEDURE informix.sp_etps_info_sjjr() returning int;
define ps_begin_date  DATETIME YEAR TO SECOND;
define li_errcode integer;
on exception
	set li_errcode
	return li_errcode;
end exception; 

set debug file to '/home/informix/sp_etps_info_sjjr.txt';
trace on;
-----------------------------------------------------------------企业---------------------------------------------------------------------------------------------
--项目代码
create temp table temp_st_pro_name(st_pro_name varchar(200),event_code varchar(10), leader_day int,commit_day int,sub_obj_id varchar(10))  with no log;

insert into temp_st_pro_name(st_pro_name, event_code, leader_day, commit_day, sub_obj_id) values('企业集团设立登记', '0711', 5, 5, 'G0');
insert into temp_st_pro_name(st_pro_name, event_code, leader_day, commit_day, sub_obj_id) values('外国企业常驻代表机构登记', '0712', 15, 5, '40');
insert into temp_st_pro_name(st_pro_name, event_code, leader_day, commit_day, sub_obj_id) values('各类企业及其分支机构营业的许可', '0717', 5, 5, '99');

create temp table temp_app_type(type_id varchar(10),type_name varchar(50))  with no log;
insert into temp_app_type(type_id,type_name) values('02','申办');
insert into temp_app_type(type_id,type_name) values('03','变更');
insert into temp_app_type(type_id,type_name) values('10','注销');
insert into temp_app_type(type_id,type_name) values('07','其它');
insert into temp_app_type(type_id,type_name) values('08','其它');
insert into temp_app_type(type_id,type_name) values('13','变更');
insert into temp_app_type(type_id,type_name) values('14','变更');
--11?


--查询上一次抽取时间
select last_extract_time into ps_begin_date
from sgb_data_extract_log;

--查询企业申请案表
select app_no,etps_name,apply_organ,approve_date,change_items_gb,accept_date,
case when sub_obj_id ='40' then '40'
	 when sub_obj_id in ('G1','G2') then 'G0' else '99' end sub_obj_type,app_date,app_type_id
	 from etps@qrypermitsoc:etps_app_actv 
where app_date >= ps_begin_date 
--and etps_id is not null
into temp tmp_etps_app with no log;

insert into tmp_etps_app
select app_no,etps_name,apply_organ,approve_date,change_items_gb,accept_date,
case when sub_obj_id ='40' then '40'
	 when sub_obj_id in ('G1','G2') then 'G0' else '99' end sub_obj_type,app_date,app_type_id
	 from etps@qrypermitsoc:etps_app_hs
where app_date >= ps_begin_date and etps_id is not null;

create index tmp_app_no_idx on tmp_etps_app(app_no);

--查询办理日期最小的
select a.app_no,min(b.subscription_date) as subscription_date from tmp_etps_app a,etps@qrypermitsoc:etps_app_node_actv b
where a.app_no= b.app_no
group by 1
into temp temp2 with no log;

insert into temp2
select a.app_no,min(b.subscription_date) as subscription_date from tmp_etps_app a,etps@qrypermitsoc:etps_app_node_hs b
where a.app_no= b.app_no
group by 1;

create index tmp_app_no2 on temp2(app_no);

select distinct a.app_no,b.staff_name,b.user_id,b.result_name,b.text_opnn from temp2 a,etps@qrypermitsoc:etps_app_node_actv b
where a.app_no = b.app_no and a.subscription_date = b.subscription_date
into temp temp3 with no log;

insert into temp3
select distinct a.app_no,b.staff_name,b.user_id,b.result_name,b.text_opnn from temp2 a,etps@qrypermitsoc:etps_app_node_hs b
where a.app_no = b.app_no and a.subscription_date = b.subscription_date;

create index t_tmp3_app_no on temp3(app_no);

--查询申请表
select a.*,b.staff_name,b.user_id,b.result_name,b.text_opnn,
c.persn_name,c.cert_type,c.cert_no,c.telephone,c.mobile,c.mail
 from tmp_etps_app a left join temp3 b
on a.app_no = b.app_no left join etps@qrypermitsoc:etps_contact_actv c
on a.app_no = c.app_no
into temp tmp_etps with no log;

--查询申请案具体表
select a.*,c.persn_name,c.cert_type,c.cert_no,b.status_id,b.result_name
 from tmp_etps_app a left join etps@qrypermitsoc:etps_app_node_actv b
on a.app_no = b.app_no left join etps@qrypermitsoc:etps_contact_actv c
on a.app_no = c.app_no where (b.result_name='收件' or b.result_id='01')
into temp tmp_jc_apply with no log;

insert into tmp_jc_apply
select a.*,c.persn_name,c.cert_type,c.cert_no,b.status_id,b.result_name
 from tmp_etps_app a left join etps@qrypermitsoc:etps_app_node_hs b
on a.app_no = b.app_no left join etps@qrypermitsoc:etps_contact_hs c
on a.app_no = c.app_no where (b.result_name='收件' or b.result_id='01');

--审核过的申请案
select a.*,b.status_id,b.result_name,b.user_id,b.staff_name  
 from tmp_etps_app a left join etps@qrypermitsoc:etps_app_node_actv b
on a.app_no = b.app_no  where ( b.actn_id='0040')
into temp tmp_jc_audit with no log;

insert into tmp_jc_audit
select a.*,b.status_id,b.result_name,b.user_id,b.staff_name 
 from tmp_etps_app a left join etps@qrypermitsoc:etps_app_node_hs b
on a.app_no = b.app_no  where ( b.actn_id='0040');


--JC_APPLICATION 添加企业
select app_no||'SHGSSH' as st_pid,
	'SHGSSH'||app_no||b.event_code as st_apply_id,
	'SHGSSH' as st_src,
	app_no as st_src_pid,
	b.event_code as st_item_id,
	b.st_pro_name as st_item_name,
	'SHGSSH' as st_org_id,
	'上海市工商行政管理局' as st_org_name,
	apply_organ as st_dept_name,
	etps_name as st_pro_name,
	approve_date as dt_do_time,
	staff_name as st_person_name,
	user_id as st_person_no,
	'' as st_person_duty,
	result_name as st_result,
	text_opnn as st_opinion,
	'' as st_days_type, 
	'' as nm_commitment_days,
	'' as nm_real_days,
	etps_name as st_applicant_name,
	'法人' as ST_APPLICANT_TYPE,
	persn_name as ST_CONTACT,
	telephone as ST_CONTACT_PHONE,
	mobile as ST_CONTACT_MOBILE,
	mail as ST_CONTACT_EMAIL,
	'窗口提交' as  ST_APPLY_METHOD,
	change_items_gb as ST_APPLY_CONTENT,
	'' as dt_intime,--不详
	'' as st_ctct_prs_name,--不详
	'' as st_ctct_prs_phone,--不详
	'' as st_ctct_prs_mobile,--不详
	'' as ST_WEBAPP_PASS,
	accept_date as DT_CLCTDOCS_TIME,
	'' as ST_APPLY_DOC_NO,--不详
	'' as dt_end,--不详
	'' as dt_begin,--不详
	cert_type as ST_CONTACT_DOCU_TYPE,
	cert_no as ST_CONTACT_DOCU_NO
 from tmp_etps a,temp_st_pro_name b
where a.sub_obj_type = b.sub_obj_id
into temp tmp_etps_application with no log;



--JC_APPLY
select b.event_code||'SHGSSH'||app_no as st_apply_id,
	'' as st_suid,
	app_no as ST_SRC_APPLY_ID,
	'SHGSSH' as st_src,
	'' as st_org_name,--不详
	'' as st_org_id,--不详
	b.event_code as st_item_id,
	b.st_pro_name as st_item_name,
	etps_name as st_pro_name,  --add
	apply_organ as st_dept_name,
    d.type_name as st_apply_type, 
	c.name as st_region,
	'单部门' as st_type,
	app_date as  dt_apply_time,
	approve_date as dt_accept_time,
	'' as dt_unsertake_time,--不详
	'' as dt_audit_time,--不详
	'' as dt_approval_time,--不详
	'' as dt_finish_time,--不详
	'' as nm_law_days,
	'' as nm_days,
	'' st_is_public,
	status_id as st_status,
	'' as st_disp_status,--不详
	result_name as st_do_result,
	'' as st_yj,
	'' as st_huangp,
	'' as st_hongp,
	'' as st_dc,
	'' as st_exp,
	'' as st_cp,
	'' as st_rule_check,
	'' as dt_intime,
	app_no as st_project_id, 
	persn_name as st_apply_person,
	'' as st_reg_address, 
	'' as st_item_type, 
	'' as st_bl_node_name, 
	'' as ST_APP_TYPE,
	'' as st_sub_item_id, 
	'' as st_sub_item_name, 
	'' as st_applicant_docu_type, 
	'' as st_applicant_docu_no
from tmp_jc_apply a left join temp_st_pro_name b
on a.sub_obj_type = b.sub_obj_id left join framework@commonsoc:organ_node c
on a.apply_organ = c.code left join temp_app_type d
on a.app_type_id = d.type_id
into temp tmp_etps_apply with no log;

select app_no||'SHGSSH' as ST_PID,b.event_code||'SHGSSH'||app_no as st_apply_id,
'SHGSSH' as st_src,app_no,b.event_code as st_item_id,
b.st_pro_name as st_item_name,etps_name as st_pro_name, apply_organ as st_dept_name,
approve_date as dt_do_time,staff_name as st_person_name,user_id as st_person_no,'' as duty,
'审核通过' as result,text_opnn as st_opinion,
	'' as st_days_type, 
	'' as nm_commitment_days,
	'' as nm_real_days,'' as dt_intime,'' as dt_end,'' as dt_begin

from tmp_jc_audit a
left join temp_st_pro_name b on a.sub_obj_type = b.sub_obj_id
into temp tmp_etps_audit;


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
from tmp_etps_application b ;

--审核表
insert into JC_AUDIT
select * from tmp_etps_audit;

drop table tmp_etps_application;
drop table tmp_etps_apply;


	
return 0;
end procedure;
GO
