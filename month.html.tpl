<!DOCTYPE html>
<html>
<head>
<script type="text/javascript" src="/js/jquery-3.3.1.js"></script>
<link rel="stylesheet" href="/js/jquery-ui-1.12.1/themes/smoothness/jquery-ui.css">
<script type="text/javascript" src="/js/jquery-ui-1.12.1/jquery-ui.min.js"></script>  
<script type="text/javascript" src="/js/jquery-ui-1.12.1/ui/i18n/datepicker-ja.js"></script>
<script type="text/javascript" src="/js/Chart.js"></script>
<link rel="stylesheet" href="/css/tepco.css">
<script>
var myChart
$(function(){
    $('#monthlist').selectmenu({
        select: function(event, ui){ monthSelected($('#monthlist').val()) }
    });
});

function monthSelected(value){
    var xhreq = new XMLHttpRequest();
    xhreq.onload = function(){
        if (xhreq.readyState === 4){
            if (xhreq.status === 200){
                var days = JSON.parse(xhreq.response)
                var labels = new Array()
                var total = new Array()
                var morning = new Array()
                var daytime = new Array()
                var evening = new Array()
                var night = new Array()
                var ave_temp = new Array()
                var low_temp = new Array()
                var high_temp = new Array()

                for (var e in days){
                    var d = days[e]
                    labels.push(d.Date)
                    total.push(d.Total)
                    morning.push(d.Morning)
                    daytime.push(d.Daytime)
                    evening.push(d.Evening)
                    night.push(d.Night)
                    ave_temp.push(d.AverageTemperature)
                    low_temp.push(d.LowestTemperature)
                    high_temp.push(d.HighestTemperature)
                }
                updateStackedBarGraph(value, labels, night, morning, daytime, evening, ave_temp, low_temp, high_temp)
            } else {
                clearGraph();
            }
        }
    }
    var query = "ym=" + value
    xhreq.open('GET', '/monthjson?'+query)
    xhreq.send()
}

$(document).ready(function(){
    getMonthlyData()
    monthSelected($('#monthlist').val()) 
});

function clearGraph(){
    if ( myChart ){
        myChart.destroy();
    }
}

function getMonthlyData(){
    updateMonthList({{.}})
}

function updateMonthList(list){
    list.forEach(function(elem){
        $('#monthlist').append($('<option>', {
            value: elem,
            text: elem,
        }))
    })
    $('#monthlist').selectmenu('refresh', true);
}

function updateGraph(title, labels, monthdata){
    var ctx = document.getElementById("myChart").getContext('2d');
    clearGraph()
    myChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: title,
                data: monthdata,
                borderWidth: 1
            }]
        },
        options: {
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero:true,
                        max: 80
                    }
                }]
            }
        }
    });
}

function updateStackedBarGraph(title, labels, night, morning, daytime, evening,
                                ave_temp, low_temp, high_temp){
    var ctx = document.getElementById("myChart").getContext('2d');
    clearGraph()
    myChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [
                {
                    label: "Avg.",
                    type: 'line',
                    data: ave_temp,
                    yAxisID: "tempYAxes",
                    fill: false,
                    borderColor: 'gray',
                    backgroundColor: 'gray',
                },
                {
                    label: "Low.",
                    type: 'line',
                    data: low_temp,
                    yAxisID: "tempYAxes",
                    fill: false,
                    borderColor: 'turquoise',
                    backgroundColor: 'turquoise',
                    pointBackgroundColor: 'cadetblue',
                    pointBorderColor: 'cadetblue',                    
                    borderDash: [5,6],
                },
                {
                    label: "High.",
                    type: 'line',
                    data: high_temp,
                    yAxisID: "tempYAxes",
                    fill: false,
                    borderColor: 'gold',
                    backgroundColor: 'gold',
                    pointBackgroundColor: 'darkorange',
                    pointBorderColor: 'darkorange',                    
                    borderDash: [5,6]
                },
                {
                    label: "night",
                    data: night,
                    backgroundColor: 'steelblue',
                    yAxisID: "barYAxes",
                },
                {
                    label: "morning",
                    data: morning,
                    backgroundColor: 'mediumseagreen',
                    yAxisID: "barYAxes",                    
                },
                {
                    label: "daytime",
                    data: daytime,
                    backgroundColor: 'peachpuff',
                    yAxisID: "barYAxes",                    
                },
                {
                    label: "evening",
                    data: evening,
                    backgroundColor: 'coral',
                    yAxisID: "barYAxes",                   
                },
            ]
        },
        options: {
            animation: {
                duration: 0,
            },
            elements: {
                line: {
                    tension: 0,
                },
            },
            scales: {
                xAxes: [{
                    stacked: true,
                }],
                yAxes: [
                    {
                        id: "barYAxes",
                        position: "left",
                        stacked: true,
                        ticks: {
                            beginAtZero:true,
                            max: 80
                        },
                        gridLines: {
                            color: "silver",
                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'kWh',
                            fontSize: 18,
                        },
                    },
                    {
                        id: "tempYAxes",
                        position: "right",
                        ticks: {
                            max: 40,
                            min: -15,
                        },
                        gridLines: {
                            color: 'silver',
                            borderDash: [5,5]
                        },
                        scaleLabel: {
                            display: true,
                            labelString: '℃',
                            fontSize: 18,                            
                        },
                    }
                ]
            }
        }
    });
    
}
</script>
</head>
<body>
<select name="monthlist" id="monthlist">
</select>
<div class="chart-container">
    <canvas id="myChart"></canvas>
</div>
</body>
</html>
