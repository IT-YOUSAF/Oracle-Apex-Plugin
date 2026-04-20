var NamosDashboard = NamosDashboard || {};

NamosDashboard.charts = NamosDashboard.charts || {};

NamosDashboard.init = function (config) {
  var regionId = config.regionId;
  var ajaxId = config.ajaxId || $('#' + regionId + '_dashboard').attr('data-ajax-id');
  var chartType = (config.chartType || 'bar').toLowerCase();

  if (!regionId || !ajaxId) {
    console.error('Missing regionId or ajaxId');
    return;
  }

  NamosDashboard.loadKPIs(regionId, ajaxId);
  NamosDashboard.loadBarChart(regionId, ajaxId, chartType);
  NamosDashboard.loadPieChart(regionId, ajaxId);
  NamosDashboard.loadTable(regionId, ajaxId);
};

NamosDashboard.loadKPIs = function (regionId, ajaxId) {
  apex.server.plugin(ajaxId, { x01: 'KPI' }, {
    dataType: 'json',
    success: function (data) {
      var container = $('#' + regionId + '_kpi');
      container.empty();

      if (!data || data.error) {
        container.html('<div class="namos-error">' + (data && data.error ? data.error : 'KPI Ajax failed') + '</div>');
        return;
      }

      if (!data.kpis || !data.kpis.length) {
        container.html('<div class="namos-empty">No KPI data found</div>');
        return;
      }

$.each(data.kpis, function (i, kpi) {
  var trendClass = (kpi.trend_type || '').toLowerCase() === 'negative' ? 'negative' : 'positive';

  container.append(
    '<div class="namos-kpi-card" style="border-top-color:' + (kpi.color || '#4a90e2') + '">' +
      '<div class="namos-kpi-icon">' +
        '<span class="fa ' + (kpi.icon || 'fa-chart-bar') + '"></span>' +
      '</div>' +
      '<div class="namos-kpi-value">' + (kpi.value || '') + '</div>' +
      '<div class="namos-kpi-label">' + (kpi.label || '') + '</div>' +
      (kpi.subtext
        ? '<div class="namos-kpi-subtext ' + trendClass + '">' + kpi.subtext + '</div>'
        : '') +
    '</div>'
  );
});
    },
    error: function (xhr, status, err) {
      console.error('KPI load failed:', status, err, xhr && xhr.responseText);
      $('#' + regionId + '_kpi').html('<div class="namos-error">KPI Ajax failed</div>');
    }
  });
};

NamosDashboard.loadBarChart = function (regionId, ajaxId, chartType) {
  apex.server.plugin(ajaxId, { x01: 'BARCHART' }, {
    dataType: 'json',
    success: function (data) {
      var canvas = document.getElementById(regionId + '_barchart');
      if (!canvas) return;

      if (!data || data.error) {
        $('#' + regionId + '_barchart').replaceWith('<div class="namos-error">' + (data && data.error ? data.error : 'Bar chart Ajax failed') + '</div>');
        return;
      }

      var labels = data.labels || [];
      var values = data.values || [];

      if (!labels.length || !values.length) {
        var wrap = canvas.parentNode;
        wrap.innerHTML = '<div class="namos-chart-title">Monthly Revenue</div><div class="namos-empty">No bar chart data found</div>';
        return;
      }

      if (NamosDashboard.charts[regionId + '_bar']) {
        NamosDashboard.charts[regionId + '_bar'].destroy();
      }

      NamosDashboard.charts[regionId + '_bar'] = new Chart(canvas, {
        type: (chartType === 'line' ? 'line' : 'bar'),
        data: {
          labels: labels,
          datasets: [{
            label: 'Revenue',
            data: values,
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false
        }
      });
    },
    error: function (xhr, status, err) {
      console.error('BARCHART load failed:', status, err, xhr && xhr.responseText);
      $('#' + regionId + '_barchart').parent().html('<div class="namos-chart-title">Monthly Revenue</div><div class="namos-error">Bar chart Ajax failed</div>');
    }
  });
};

NamosDashboard.loadPieChart = function (regionId, ajaxId) {
  apex.server.plugin(ajaxId, { x01: 'PIECHART' }, {
    dataType: 'json',
    success: function (data) {
      var canvas = document.getElementById(regionId + '_piechart');
      if (!canvas) return;

      if (!data || data.error) {
        $('#' + regionId + '_piechart').parent().html('<div class="namos-chart-title">Order Status</div><div class="namos-error">' + (data && data.error ? data.error : 'Pie chart Ajax failed') + '</div>');
        return;
      }

      var slices = data.slices || [];
      if (!slices.length) {
        $('#' + regionId + '_piechart').parent().html('<div class="namos-chart-title">Order Status</div><div class="namos-empty">No pie chart data found</div>');
        return;
      }

      if (NamosDashboard.charts[regionId + '_pie']) {
        NamosDashboard.charts[regionId + '_pie'].destroy();
      }

      NamosDashboard.charts[regionId + '_pie'] = new Chart(canvas, {
        type: 'pie',
        data: {
          labels: slices.map(function (s) { return s.label; }),
          datasets: [{
            data: slices.map(function (s) { return s.value; })
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false
        }
      });
    },
    error: function (xhr, status, err) {
      console.error('PIECHART load failed:', status, err, xhr && xhr.responseText);
      $('#' + regionId + '_piechart').parent().html('<div class="namos-chart-title">Order Status</div><div class="namos-error">Pie chart Ajax failed</div>');
    }
  });
};

NamosDashboard.loadTable = function (regionId, ajaxId) {
  apex.server.plugin(ajaxId, { x01: 'TABLE' }, {
    dataType: 'json',
    success: function (data) {
      var el = $('#' + regionId + '_tablediv');
      el.empty();

      if (!data || data.error) {
        el.html('<div class="namos-error">' + (data && data.error ? data.error : 'Table Ajax failed') + '</div>');
        return;
      }

      if (!data.columns || !data.columns.length) {
        el.html('<div class="namos-empty">No table data found</div>');
        return;
      }

      var html = '<table id="' + regionId + '_tbl" class="namos-tbl"><thead><tr>';

      data.columns.forEach(function (col) {
        html += '<th>' + col + '</th>';
      });

      html += '</tr></thead><tbody>';

(data.rows || []).forEach(function (row) {
  html += '<tr>';

  data.columns.forEach(function (col) {
    var val = (row[col] == null ? '' : row[col]);
    var colName = String(col || '').toLowerCase();
console.log('COLUMN=', '[' + col + ']', 'NORMALIZED=', '[' + colName + ']', 'VALUE=', '[' + val + ']');
    if (colName === 'status') {
      var statusClass = 'status-default';
      var statusText = String(val).toLowerCase();

      if (statusText === 'completed') {
        statusClass = 'status-completed';
      } else if (statusText === 'pending') {
        statusClass = 'status-pending';
      } else if (statusText === 'cancelled' || statusText === 'canceled') {
        statusClass = 'status-cancelled';
      }

      html += '<td><span class="namos-status-badge ' + statusClass + '">' + val + '</span></td>';
    } else {
      html += '<td>' + val + '</td>';
    }
  });

  html += '</tr>';
});

      html += '</tbody></table>';
      el.html(html);
    },
    error: function (xhr, status, err) {
      console.error('TABLE load failed:', status, err, xhr && xhr.responseText);
      $('#' + regionId + '_tablediv').html('<div class="namos-error">Table Ajax failed</div>');
    }
  });
};

NamosDashboard.filterTable = function (input) {
  if (!input) return;

  var tableId = $(input).attr('data-target-table');
  if (!tableId) return;

  var filter = ($(input).val() || '').toLowerCase();

  $('#' + tableId + ' tbody tr').each(function () {
    $(this).toggle($(this).text().toLowerCase().indexOf(filter) > -1);
  });
};