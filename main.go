package main

import (
	"bufio"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"log"
	"math"
	"net/http"
	"os"
	"sort"
	"strconv"
	"strings"
)

type DayData struct {
	Date        string    `json:"Date"`
	RawData     []float64 `json:"RawData"`
	Total       float64   `json:"Total"`
	Daytime     float64   `json:"Daytime"`
	Evening     float64   `json:"Evening"`
	Morning     float64   `json:"Morning"`
	Night       float64   `json:"Night"`
	RawTemp     []float64 `json:"RawTemperature"`
	HighestTemp float64   `json:"HighestTemperature"`
	LowestTemp  float64   `json:"LowestTemperature"`
	AverageTemp float64   `json:"AverageTemperature"`
}

type MonthData struct {
	Month int              `json:"Month"`
	Days  map[int]*DayData `json:"Days"`
}

type YearData struct {
}

var allDayData map[string]*DayData
var allMonthData map[string]MonthData
var monthList []string

func main() {
	loadData()
	loadRawTemperature(allDayData)
	loadDateTemperature(allDayData)
	http.Handle("/js/", http.StripPrefix("/js/", http.FileServer(http.Dir("js/"))))
	http.Handle("/css/", http.StripPrefix("/css/", http.FileServer(http.Dir("css/"))))
	http.HandleFunc("/day/", dayHandler)
	http.HandleFunc("/dayjson", dayJSONHandler)
	http.HandleFunc("/month/", monthHandler)
	http.HandleFunc("/monthjson", monthJSONHandler)
	log.Fatal(http.ListenAndServe("localhost:8000", nil))
}

func loadData() {
	datafilename := "alldata.txt"
	f, err := os.OpenFile(datafilename, os.O_RDONLY, 0666)
	if err != nil {
		log.Fatal(err)
	}

	allDayData = make(map[string]*DayData)
	allMonthData = make(map[string]MonthData)

	input := bufio.NewScanner(f)
	for input.Scan() {
		if len(input.Text()) == 0 {
			continue
		}
		s := strings.Split(input.Text(), ",")
		d := strings.Replace(s[0], "/", "", -1)

		fdata := make([]float64, len(s[1:]))
		for i, e := range s[1:] {
			fdata[i], _ = strconv.ParseFloat(e, 64)
		}
		m := timeOfDay(fdata)
		allDayData[d] = &DayData{d, fdata, m["total"], m["daytime"], m["evening"], m["morning"], m["night"],
			[]float64{}, math.NaN(), math.NaN(), math.NaN()}

		yyyymmdd := strings.Split(s[0], "/")
		kkk := strings.Join(yyyymmdd[0:2], "/")
		month, _ := strconv.Atoi(yyyymmdd[1])
		_, haskey := allMonthData[kkk]
		if !haskey {
			allMonthData[kkk] = MonthData{month, make(map[int]*DayData)}
		}
		day, _ := strconv.Atoi(yyyymmdd[2])
		allMonthData[kkk].Days[day] = allDayData[d]
	}

	for k := range allMonthData {
		monthList = append(monthList, k)
	}
	sort.Strings(monthList)
}

func dayHandler(w http.ResponseWriter, r *http.Request) {
	t := template.Must(template.ParseFiles("day.html.tpl"))
	if err := t.ExecuteTemplate(w, "day.html.tpl", nil); err != nil {
		log.Fatal(err)
	}
}

func dayJSONHandler(w http.ResponseWriter, r *http.Request) {
	queryDate := r.URL.Query()["date"]
	if data, haskey := allDayData[queryDate[0]]; haskey {
		json.NewEncoder(w).Encode(data)
	} else {
		http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
	}
}

func monthHandler(w http.ResponseWriter, r *http.Request) {
	t := template.Must(template.ParseFiles("month.html.tpl"))
	if err := t.ExecuteTemplate(w, "month.html.tpl", monthList); err != nil {
		log.Fatal(err)
	}
}

func monthJSONHandler(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()["ym"]
	if m, haskey := allMonthData[q[0]]; haskey {
		json.NewEncoder(w).Encode(m.Days)
	} else {
		http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
	}
}

func sum(data []float64) float64 {
	total := 0.0
	for _, v := range data {
		total += v
	}
	return total
}
func timeOfDay(fdata []float64) map[string]float64 {
	total := sum(fdata)
	night := sum(append(fdata[0:14], fdata[46:48]...))
	morning := sum(fdata[14:20])
	daytime := sum(fdata[20:34])
	evening := sum(fdata[34:46])
	return map[string]float64{"total": total, "night": night, "morning": morning, "daytime": daytime, "evening": evening}
}

func normalizeDate(strDate string) string {
	c := strings.Split(strDate, "/")
	y := c[0]
	m, _ := strconv.Atoi(c[1])
	d, _ := strconv.Atoi(c[2])
	return fmt.Sprintf("%s%02d%02d", y, m, d)
}

func loadRawTemperature(alldaydata map[string]*DayData) {
	filename := "otawara/temperature/otawara_temperature_detail.csv"
	f, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
	}
	csvr := csv.NewReader(f)
	for {
		l, err := csvr.Read()
		if err == io.EOF {
			break
		} else if err != nil {
			log.Fatal(err)
		}
		var strDate, strTime string
		if n, err := fmt.Sscanf(l[0], "%s%s", &strDate, &strTime); err != nil {
			log.Fatal(err)
		} else if n != 2 {
			log.Fatal("couldn't get date time")
		}
		normDate := normalizeDate(strDate)
		temp, err := strconv.ParseFloat(l[1], 64)
		_, haskey := alldaydata[normDate]
		if !haskey {
			continue
		}
		alldaydata[normDate].RawTemp = append(alldaydata[normDate].RawTemp, temp)
	}
}

func loadDateTemperature(alldaydata map[string]*DayData) {
	filename := "otawara/temperature/otawara_date_temperature.csv"
	f, err := os.Open(filename)
	if err != nil {
		log.Fatal(err)
	}
	csvr := csv.NewReader(f)
	for {
		l, err := csvr.Read()
		if err == io.EOF {
			break
		} else if err != nil {
			log.Fatal(err)
		}
		if len(l) != 14 {
			log.Fatal("invalid input")
		}
		normDate := normalizeDate(l[0])
		_, haskey := alldaydata[normDate]
		if !haskey {
			continue
		}
		averageTemp, _ := strconv.ParseFloat(l[1], 64)
		highestTemp, _ := strconv.ParseFloat(l[4], 64)
		lowestTemp, _ := strconv.ParseFloat(l[9], 64)
		alldaydata[normDate].AverageTemp = averageTemp
		alldaydata[normDate].HighestTemp = highestTemp
		alldaydata[normDate].LowestTemp = lowestTemp
	}
}
