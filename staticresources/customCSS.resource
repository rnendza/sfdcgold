* {
    box-sizing: border-box;
    cursor: default;
}
*:focus {
    outline: none;
}
a {
    text-decoration: none;
}
img.content {
    padding-left: 40px;
    float: left;
}
img.exp {
    padding-top: 200px;
    margin-left: 60px;
}
html,
body {
    margin: 0;
    padding: 0;
    border: 0;
    width: 100%;
    height: 100%;
}
body {
    background: #d8d8d8;
    background-size: 100% 100%;
    background-repeat: no-repeat;
}
div#navcontainer {
    height: 84px;
    background: #000;
    background: -moz-linear-gradient(top,#000000 0%,#232323 10%,#353535 18%,#232323 31%,#4c4c4c 50%,#000000 100%);
    background: -webkit-linear-gradient(top,#000000 0%,#232323 10%,#353535 18%,#232323 31%,#4c4c4c 50%,#000000 100%);
    background: linear-gradient(to bottom,#000000 0%,#232323 10%,#353535 18%,#232323 31%,#4c4c4c 50%,#000000 100%);
    filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#000000',endColorstr='#000000',GradientType=0);
    border-bottom: 4px solid #eb0303;
    width: 100%;
}
div#navbar {
    padding-left: 3px;
}
div#imgcontainer {
    width: 23.076923077%;
    display: inline-block;
    text-align: center;
    margin: 10px 0;
}
div#navmenu {
    width: 70%;
    display: inline-block;
}
div.navmenuitem {
    color: white;
    font-family: verdana,sans-serif;
    font-size: 18px;
    float: right;
    margin-left: 40px;
    margin-right: 40px;
    padding-bottom: 18px;
}
a.navmenutext {
    text-decoration: none;
    color: white;
    font-style: normal;
    font-family: 'Roboto Condensed',sans-serif;
    letter-spacing: 1px;
    font-size: 16px;
    cursor: pointer;
}
a.navmenutext:hover {
    color: #ed1c24;
    font-weight: bold;
    text-shadow: -1px -1px 2px #383838,1px -1px 2px #383838,-1px 1px 2px #383838,1px 1px 2px #383838;
}
.clear {
    clear: both;
}
#map{
  	margin: 0;
    padding: 0;
    display: inline-block;
    height:  calc(100% - 84px);
    width: 100%;
	box-sizing: border-box;
}
.detailwindow{
    display: block;
    border-radius: 2px;
    margin: 0;
    padding: 0;
    height: 100%;
    width: 22%;
    box-shadow: 0px 0px 20px  rgba(0,0,0,.3);
    background-color: white;
    z-index: 1;
    font-family: Roboto, Arial, sans-serif;
}
.submitbtn{
    background: #ff1a1a;
    color: white;
    border-radius: 3px;
    border-color: #adb1b8 #a2a6ac #8d9096;
    border-style: solid;
    border-width: 1px;
    cursor: pointer;
    display: inline-block;
    padding: 0;
    text-align: center;
    text-decoration: none!important;
    vertical-align: middle;
    width: 100%;
    line-height: 19px;
    font-weight: 700;
    height: 29px;
    padding: 5px 1px 5px 1px;
}
.submitbtn:hover{
    background-color:  #ff5959;
}
.passbox{
    font-size: 16px;
    font-weight: 400;
    display: block;
    padding:  3px 7px 3px 7px;
    background-color: #FFF;
    height: 31px;
    padding: 3px 7px;
    line-height: normal;
    font-family: "Amazon Ember",Arial,sans-serif;
    border: 1px solid #a6a6a6;
    border-top-color: #949494;
    border-radius: 3px;
	box-shadow: 0 1px 0 rgba(255,255,255,.5), 0 1px 0 rgba(0,0,0,.07) inset;
    outline: 0;
    color: #111;
    line-height: normal;
    box-sizing: border-box;
    margin-bottom: 28px!important;
    width: 100%;
}
.userbox{
    font-size: 16px;
    font-weight: 400;
    display: block;
    padding:  3px 7px 3px 7px;
    background-color: #FFF;
    height: 31px;
    padding: 3px 7px;
    line-height: normal;
    font-family: "Amazon Ember",Arial,sans-serif;
    border: 1px solid #a6a6a6;
    border-top-color: #949494;
    border-radius: 3px;
	box-shadow: 0 1px 0 rgba(255,255,255,.5), 0 1px 0 rgba(0,0,0,.07) inset;
    outline: 0;
    color: #111;
    line-height: normal;
    box-sizing: border-box;
    margin-bottom: 14px!important;
    width: 100%;
}
div#container{
    padding-top: 150px;
    width: 350px;
    margin: 0 auto;
}
label {
    display: inline-block;
    padding-left: 2px;
    padding-bottom: 2px;
    font-weight: 700;
    font-size: 16px;
    line-height: normal;
}

.titlewrapdiv{
    padding: 10px;
    height: 80px;
    width: 100%;
    display: block;
}
.dvndiv{
    padding-left: 15px;
    height: 60px;
    width: 50%;
    display: inline-block;
    font-size: 24px;
    font-weight: 700;
    text-align: left;
    line-height: 60px;
    vertical-align:middle;
    color: #4285F4
}
.statusdiv{
    color: black;
    height: 60px;
    width: 50%;
    display: inline-block;
    font-size: 16px;
    font-weight: 400;
    font-style: italic;
    text-align: left;
    line-height: 64px;
    vertical-align: middle;
}
.detailwrapdiv{
    height: 24px;
    width: 100%;
}
.colordiv{
    padding-left: 25px;
    width: 20%;
    height: 24px;
    display: inline-block;
    font-size: 18px;
    font-weight: 700;
    text-align: left;
    line-height: 24px;
    vertical-align: middle;
    color: black;
}
.makediv{
    width: 40%;
    height: 24px;
    display: inline-block;
    font-size: 18px;
    font-weight: 700;
    text-align: center;
    line-height: 24px;
    vertical-align: middle;
    color: black;
}
.modeldiv{
    width: 40%;
    height: 24px;
    display: inline-block;
    font-size: 18px;
    font-weight: 700;
    text-align: left;
    line-height: 24px;
    vertical-align: middle;
    color: black;
}
.vindiv{
    padding-left: 25px;
    height: 24px;
    width: 100%;
    display: block;
    font-size: 16px;
    font-weight: 700;
    text-align: left;
    line-height: 24px;
    vertical-align: middle;
    color: black;
}
.licensediv{
    padding-left: 25px;
    padding-bottom: 10px;
    width: 100%;
    height: 34px;
    display: block;
    font-size: 16px;
    font-weight: 700;
    text-align: left;
    line-height: 24px;
    vertical-align: middle;
    color: black;
    border-bottom: 5px solid #4285F4;
}
.tripwrapperdiv{
    height: calc(100% - 162px);
    width: 100%;
    display: block;
    overflow-y: scroll;
}
.tripheader{
    display: inline-block;
    padding: 6px;
    width: 50%;
    height: 30px;
    background-color: lightgrey;
    font-size: 14px;
    font-weight: 700;
    text-align: center;
    line-height: 18px;
    vertical-align: middle;
	color: black;
    box-shadow: 0px 1px 2px  rgba(0,0,0,.3);
}
.tripdetail{
    display: inline-block;
    padding: 4px;
    width: 50%;
    height: 30px;
    background-color: whitesmoke;
    font-size: 13px;
    font-weight: 400;
    text-align: center;
    line-height: 22px;
    vertical-align: middle;
	color: black;
}

.scrollable-x::-webkit-scrollbar, .scrollable-y::-webkit-scrollbar {
    width: 6px;
}
.scrollable-x::-webkit-scrollbar-thumb, .scrollable-y::-webkit-scrollbar-thumb {
    background-color: #888;
}
.scrollable-x::-webkit-scrollbar-track, .scrollable-y::-webkit-scrollbar-track {
    background-color: #f0f0f0;
}