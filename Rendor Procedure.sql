create or replace package dashboard_plugin_pkg as
  procedure render(
    p_region in            apex_plugin.t_region,
    p_plugin in            apex_plugin.t_plugin,
    p_param  in            apex_plugin.t_region_render_param,
    p_result in out nocopy apex_plugin.t_region_render_result
  );

  procedure ajax(
    p_region in            apex_plugin.t_region,
    p_plugin in            apex_plugin.t_plugin,
    p_param  in            apex_plugin.t_region_ajax_param,
    p_result in out nocopy apex_plugin.t_region_ajax_result
  );
end dashboard_plugin_pkg;
/


-------------------------
create or replace package body dashboard_plugin_pkg as

  procedure render(
    p_region in            apex_plugin.t_region,
    p_plugin in            apex_plugin.t_plugin,
    p_param  in            apex_plugin.t_region_render_param,
    p_result in out nocopy apex_plugin.t_region_render_result
  ) as
    l_region_id  varchar2(255);
    l_ajax_id    varchar2(32767);
    l_chart_type varchar2(30);
  begin
    l_region_id := case
                     when p_region.static_id is not null
                          and trim(p_region.static_id) <> ''
                     then p_region.static_id
                     else 'namos_' || p_region.id
                   end;

    l_ajax_id := apex_plugin.get_ajax_identifier;

    -- chart_type is plugin attribute sequence 5
    l_chart_type := lower(nvl(p_region.attribute_05, 'bar'));

    apex_css.add(
      p_css =>
        '.namos-dashboard-container{display:flex;flex-direction:column;gap:20px;padding:16px;}' ||
        '.namos-kpi-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;}' ||
        '.namos-kpi-card{background:#fff;border-radius:10px;border:1px solid #e8e8e8;border-top-width:4px;border-top-style:solid;padding:16px;display:flex;flex-direction:column;gap:4px;}' ||
        '.namos-kpi-value{font-size:24px;font-weight:600;color:#1a1a2e;}' ||
        '.namos-kpi-label{font-size:12px;color:#888;text-transform:uppercase;letter-spacing:.5px;}' ||
        '.namos-charts-row{display:grid;grid-template-columns:1fr 1fr;gap:16px;}' ||
        '.namos-chart-container{background:#fff;border-radius:10px;border:1px solid #e8e8e8;padding:16px;min-height:340px;}' ||
        '.namos-chart-title{font-size:13px;font-weight:600;color:#333;margin-bottom:10px;}' ||
        '.namos-table-container{background:#fff;border-radius:10px;border:1px solid #e8e8e8;padding:16px;overflow-x:auto;}' ||
        '.namos-tbl{width:100%;border-collapse:collapse;font-size:13px;}' ||
        '.namos-tbl th{padding:8px 12px;text-align:left;font-size:11px;text-transform:uppercase;letter-spacing:.4px;color:#888;border-bottom:1px solid #eee;}' ||
        '.namos-tbl td{padding:9px 12px;border-bottom:1px solid #f5f5f5;color:#333;}' ||
        '.namos-tbl tr:hover td{background:#fafafa;}' ||
        '.namos-empty{padding:20px;color:#999;text-align:center;}' ||
        '.namos-error{padding:12px;color:#b42318;background:#fef3f2;border:1px solid #fecdca;border-radius:8px;}' ||
        '@media(max-width:768px){.namos-kpi-row{grid-template-columns:1fr 1fr;}.namos-charts-row{grid-template-columns:1fr;}}',
      p_key => 'namos-dashboard-css'
    );

    sys.htp.p(
      '<div id="' || apex_escape.html_attribute(l_region_id) || '_dashboard"' ||
      ' class="namos-dashboard-container"' ||
      ' data-ajax-id="' || apex_escape.html_attribute(l_ajax_id) || '"' ||
      ' data-chart-type="' || apex_escape.html_attribute(l_chart_type) || '">'
    );

    sys.htp.p('<div class="namos-kpi-row" id="' || apex_escape.html_attribute(l_region_id) || '_kpi">');
    sys.htp.p('<div class="namos-empty">Loading KPIs...</div>');
    sys.htp.p('</div>');

    sys.htp.p('<div class="namos-charts-row">');

    sys.htp.p('<div class="namos-chart-container">');
    sys.htp.p('<div class="namos-chart-title">Monthly Revenue</div>');
    sys.htp.p('<canvas id="' || apex_escape.html_attribute(l_region_id) || '_barchart" height="260"></canvas>');
    sys.htp.p('</div>');

    sys.htp.p('<div class="namos-chart-container">');
    sys.htp.p('<div class="namos-chart-title">Order Status</div>');
    sys.htp.p('<canvas id="' || apex_escape.html_attribute(l_region_id) || '_piechart" height="260"></canvas>');
    sys.htp.p('</div>');

    sys.htp.p('</div>');

    sys.htp.p('<div class="namos-table-container">');
    sys.htp.p('<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">');
    sys.htp.p('<span style="font-size:13px;font-weight:600;color:#333;">Recent Orders</span>');
    sys.htp.p(
      '<input type="text" id="' || apex_escape.html_attribute(l_region_id) || '_search"' ||
      ' placeholder="Search..."' ||
      ' data-target-table="' || apex_escape.html_attribute(l_region_id) || '_tbl"' ||
      ' style="font-size:12px;padding:5px 10px;border:1px solid #ddd;border-radius:6px;width:180px;"' ||
      ' onkeyup="NamosDashboard.filterTable(this)"/>'
    );
    sys.htp.p('</div>');
    sys.htp.p('<div id="' || apex_escape.html_attribute(l_region_id) || '_tablediv">');
    sys.htp.p('<div class="namos-empty">Loading data...</div>');
    sys.htp.p('</div>');
    sys.htp.p('</div>');

    sys.htp.p('</div>');
 
    apex_javascript.add_library(
      p_name      => 'chart.umd',
      p_directory => p_plugin.file_prefix,
      p_version   => null
    );

    apex_javascript.add_library(
      p_name      => 'dashboard',
      p_directory => p_plugin.file_prefix,
      p_version   => null
    );

    apex_javascript.add_onload_code(
      p_code =>
        'setTimeout(function(){' ||
          'if(window.NamosDashboard && typeof NamosDashboard.init === "function"){' ||
            'NamosDashboard.init({' ||
              'regionId:'  || apex_escape.js_literal(l_region_id)  || ',' ||
              'ajaxId:'    || apex_escape.js_literal(l_ajax_id)    || ',' ||
              'chartType:' || apex_escape.js_literal(l_chart_type) ||
            '});' ||
          '}else{' ||
            'console.error("NamosDashboard library not loaded.");' ||
          '}' ||
        '},200);'
    );

    p_result.navigable_dom_id := l_region_id || '_search';

  exception
    when others then
      sys.htp.p('<div class="namos-error">Dashboard Render Error: ' || apex_escape.html(sqlerrm) || '</div>');
  end render;


  procedure ajax(
    p_region in            apex_plugin.t_region,
    p_plugin in            apex_plugin.t_plugin,
    p_param  in            apex_plugin.t_region_ajax_param,
    p_result in out nocopy apex_plugin.t_region_ajax_result
  ) as
  
 
  
   l_action    varchar2(100) := apex_application.g_x01;

    -- SQL attributes must be read positionally
l_kpi_sql varchar2(32767) := p_region.attributes.get_varchar2('kpi_sql_query');
l_bar_sql varchar2(32767) := p_region.attributes.get_varchar2('line_chart');
l_pie_sql varchar2(32767) := p_region.attributes.get_varchar2('pie_chart');
l_tbl_sql varchar2(32767) := p_region.attributes.get_varchar2('data_table');

  
   l_cnt pls_integer := 0;
 


    l_cursor    sys_refcursor;
l_label       varchar2(4000);
l_value       varchar2(4000);
l_icon        varchar2(4000);
l_color       varchar2(4000);
l_subtext     varchar2(4000);
l_trend_type  varchar2(4000);

    l_cursor_id pls_integer;
    l_col_cnt   pls_integer;
    l_desc_tab  dbms_sql.desc_tab2;
    l_col_val   varchar2(4000);
    l_dummy     pls_integer;

    type t_label_tab is table of varchar2(500);
    type t_value_tab is table of varchar2(500);
    l_labels    t_label_tab := t_label_tab();
    l_values    t_value_tab := t_value_tab();
  begin
    apex_debug.message('AJAX action=%s', l_action);
    apex_debug.message('KPI SQL=%s',   substr(l_kpi_sql, 1, 200));
    apex_debug.message('BAR SQL=%s',   substr(l_bar_sql, 1, 200));
    apex_debug.message('PIE SQL=%s',   substr(l_pie_sql, 1, 200));
    apex_debug.message('TABLE SQL=%s', substr(l_tbl_sql, 1, 200));

    apex_json.open_object;
 
    if l_action = 'KPI' then
      apex_json.open_array('kpis');
 apex_debug.message('KPI row count=%s', 0.1);
    --  if l_kpi_sql is not null and trim(l_kpi_sql) <> '' then
        
        open l_cursor for l_kpi_sql;
        loop
      
          fetch l_cursor  into l_label, l_value, l_icon, l_color, l_subtext, l_trend_type;
         
          exit when l_cursor%notfound;
   l_cnt := l_cnt + 1; 
  apex_json.open_object;
  apex_json.write('label', l_label);
  apex_json.write('value', l_value);
  apex_json.write('icon',  l_icon);
  apex_json.write('color', l_color);
  apex_json.write('subtext', l_subtext);
  apex_json.write('trend_type', l_trend_type);
  apex_json.close_object; 
        end loop;
        close l_cursor;
       
     -- end if;

      apex_json.close_array;

    elsif l_action = 'BARCHART' then
      if l_bar_sql is not null then
              apex_debug.message('bar chart row count=%s', 0.1);
        open l_cursor for l_bar_sql;
        loop
          fetch l_cursor into l_label, l_value;
          exit when l_cursor%notfound;

          l_labels.extend;
          l_labels(l_labels.last) := l_label;

          l_values.extend;
          l_values(l_values.last) := l_value;
        end loop;
           apex_debug.message('bar chart row count=%s', 0.9);
        close l_cursor;
      end if;

      apex_json.open_array('labels');
      for i in 1 .. l_labels.count loop
        apex_json.write(l_labels(i));
      end loop;
      apex_json.close_array;

      apex_json.open_array('values');
      for i in 1 .. l_values.count loop
        apex_json.write(to_number(nvl(l_values(i), '0')));
      end loop;
      apex_json.close_array;

    elsif l_action = 'PIECHART' then
      apex_json.open_array('slices');
 apex_debug.message('pic chart row count=%s', 0.1);

     if l_pie_sql is not null   then
        open l_cursor for l_pie_sql;
        loop
         apex_debug.message('pic chart row count=%s', 0.2);
         l_cnt := l_cnt + 1;
          fetch l_cursor into l_label, l_value;
          exit when l_cursor%notfound;

          apex_json.open_object;
          apex_json.write('label', l_label);
          apex_json.write('value', to_number(nvl(l_value, '0')));
          apex_json.close_object;
        end loop;
         apex_debug.message('pic chart row count=%s', l_cnt);
        close l_cursor;
       end if;

      apex_json.close_array;

    elsif l_action = 'TABLE' then
      apex_json.open_array('columns');
              apex_debug.message('table chart row count=%s', 0.1);
      if l_tbl_sql is not null  then
        l_cursor_id := dbms_sql.open_cursor;
        dbms_sql.parse(l_cursor_id, l_tbl_sql, dbms_sql.native);
        dbms_sql.describe_columns2(l_cursor_id, l_col_cnt, l_desc_tab);

        for i in 1 .. l_col_cnt loop
          dbms_sql.define_column(l_cursor_id, i, l_col_val, 4000);
          apex_json.write(l_desc_tab(i).col_name);
        end loop;

        apex_json.close_array;

        l_dummy := dbms_sql.execute(l_cursor_id);

        apex_json.open_array('rows');
        loop
          exit when dbms_sql.fetch_rows(l_cursor_id) = 0;
          apex_json.open_object;
          for i in 1 .. l_col_cnt loop
            dbms_sql.column_value(l_cursor_id, i, l_col_val);
            apex_json.write(l_desc_tab(i).col_name, nvl(l_col_val, ''));
          end loop;
          apex_json.close_object;
        end loop;
        apex_json.close_array;

        dbms_sql.close_cursor(l_cursor_id);
        l_cursor_id := null;
      else
        apex_json.close_array;
        apex_json.open_array('rows');
        apex_json.close_array;
      end if;

    else
      apex_json.write('error', 'Unsupported action: ' || l_action);
    end if;

    apex_json.close_object;


    apex_debug.message('ITZAZ  =%s',   substr(l_pie_sql, 1, 200));
 
  exception
    when others then
      begin
        if l_cursor_id is not null and dbms_sql.is_open(l_cursor_id) then
          dbms_sql.close_cursor(l_cursor_id);
        end if;
      exception
        when others then
          null;
      end;

      begin
        if l_cursor%isopen then
          close l_cursor;
        end if;
      exception
        when others then
          null;
      end;

      apex_json.close_all;
      apex_json.open_object;
      apex_json.write('error', sqlerrm);
      apex_json.close_object;
  end ajax;

end dashboard_plugin_pkg;
/