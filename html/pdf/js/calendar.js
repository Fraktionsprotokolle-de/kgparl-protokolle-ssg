let KGParlColors = {"Grüne": "#00FF00", "Linke": "#FF0000", "CDU/CSU": "#000000", "SPD": "#FF0000", "PDS": "#800080", "FDP": "#FFFF00"}


var response = KGParlData;
var result = JSON.stringify(response);
const jsonArray = JSON.parse(result);
const data =
       jsonArray.map(r => ({
        id: r.id,
        startDate: new Date(r.startDate),
        endDate: new Date(r.startDate),
        fraction: r.fraktion,
        topics: r.topics,
        name: r.name,
        url:
          window.location.protocol +
          "//" +
          window.location.host +
          "/" +
          r.id,
        color: KGParlColors[r.fraktion],
      }));
console.log(data);

new Calendar("#calendar", {
  language: "de",
  enableRangeSelection: true,
  minDate: new Date(1949, 01, 01),
  maxDate: new Date(1990, 12, 31),
  startYear: 1949,
/*  mouseOnDay: handleEnterDay,
  mouseOutDay: handleLeaveDay,*/
  dataSource: data
    // Load data from js object
});
