<!DOCTYPE html>
<html>
<head>
<script type="text/javascript" src="/js/jquery-3.3.1.min.js"></script>
<link rel="stylesheet" href="/js/jquery-ui-1.12.1/themes/smoothness/jquery-ui.css">
<script type="text/javascript" src="/js/jquery-ui-1.12.1/jquery-ui.min.js"></script>  
<script type="text/javascript" src="/js/jquery-ui-1.12.1/ui/i18n/datepicker-ja.js"></script>
<script type="text/javascript" src="/js/Chart.js"></script>
<link rel="stylesheet" href="/css/tepco.css">
<script>
var myChart
$(function() {
    $("#datepicker").datepicker({
        onSelect: function(selected) {
            var xhreq = new XMLHttpRequest();
            xhreq.onload = function(){
                if (xhreq.readyState === 4){
                    if (xhreq.status === 200){
                        d = JSON.parse(xhreq.response)
                       jsonToGraph(d)
                    } else {
                        clearGraph();
                    }
                }
            }
            xhreq.onerror = function(){
                clearGraph()
            }
            var query = "date="+selected.split('/').join('')
            xhreq.open('GET', '/dayjson?'+query)
            xhreq.send()
        }
    });
});

function clearGraph(){
    if ( myChart ){
        myChart.destroy();
    }
}

function jsonToGraph(d){
    updateGraph(d.Date, d.RawData, d.Total)
}

function updateGraph(date, timedata, total){
   var timeLabel = ["0:00","","","",
                 "2:00","","","",
                 "4:00","","","",
                 "6:00","","","",
                 "8:00","","","",
                 "10:00","","","",
                 "12:00","","","",
                 "14:00","","","",
                 "16:00","","","",
                 "18:00","","","",
                 "20:00","","","",
                 "22:00","","","",
                 "24:00"]
    var barColors = ["#1b61ae","#1b61ae","#1b61ae","#1b61ae",
                 "#1b61ae","#1b61ae","#1b61ae","#1b61ae",
                 "#1b61ae","#1b61ae","#1b61ae","#1b61ae",
                 "#1b61ae","#1b61ae","#ffba00","#ffba00",
                 "#ffba00","#ffba00","#ffba00","#ffba00",
                 "#e85c5f","#e85c5f","#e85c5f","#e85c5f",
                 "#e85c5f","#e85c5f","#e85c5f","#e85c5f",
                 "#e85c5f","#e85c5f","#e85c5f","#e85c5f",
                 "#e85c5f","#e85c5f","#ffba00","#ffba00",
                 "#ffba00","#ffba00","#ffba00","#ffba00",
                 "#ffba00","#ffba00","#ffba00","#ffba00",
                 "#ffba00","#ffba00","#1b61ae","#1b61ae",
                 "#1b61ae"]

    var ctx = document.getElementById("myChart").getContext('2d');
    clearGraph()
    myChart = new Chart(ctx, {
    type: 'bar',
    data: {
        labels: timeLabel,
        datasets: [{
            label: date + "  : Total = " + total.toFixed(1),
            data: timedata,
            backgroundColor: barColors,
            borderColor: barColors,
            borderWidth: 1
        }]
    },
    options: {
        maintainAspectRatio: false,
        scales: {
            yAxes: [{
                ticks: {
                    beginAtZero:true,
                    max: 4
                }
            }]
        }
    }
}); 
}
</script>
</head>

<body>
<div id="datepicker"></div>
<div class="chart-container">
    <canvas id="myChart"></canvas>
</div>
</body>
</html>
