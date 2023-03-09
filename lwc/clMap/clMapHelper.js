export default class ClMapHelper {

    addMapMarkerMarker(map,geoCoord,customIconInfo) {

        console.log('--> add custom info',customIconInfo);
        let marker;
        if(!geoCoord) {
            console.warn('--> no geo coords passed for marker!');
            return;
        }
        console.log('--> add marker coords',JSON.parse(JSON.stringify(geoCoord)));

        let lat = geoCoord.latitude, lng = geoCoord.longitude;

        if(customIconInfo) {
            const divIcon = L.divIcon( customIconInfo.divIcon );
            marker = L.marker([lat,lng],{ icon:  divIcon});
        } else {
            marker = L.marker([lat,lng]);
        }
        marker.on('click', function(e){
            map.setView(e.latlng, 14);
        });
        if(customIconInfo && customIconInfo.toolTip) {
            marker.bindTooltip(customIconInfo.toolTip, {direction: 'top', offset: [0,-30]});
        }
        marker.addTo(map);
    }

    setMapTileLayer(state,map) {

        L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token='+state.accessToken, {
            attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">' +
                'OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
                'Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
            maxZoom: state.maxZoom,
            minZoom: state.minZoom,
            id: state.mapboxStyleUrlSuffix,
            tileSize: state.tileSize,
            zoomOffset: state.zoomOffset,
            accessToken: state.accessToken
        }).addTo(map);

        console.log('added tile layer to map');
    }

    removeMap(map) {
        if(map) {
            console.info('----> clearing map layers!');
            map.eachLayer(function (layer) {
                layer.remove();
            });

            map.remove();
            map = null;
            console.info('----> removing map!');
        }
    }

    getUserCurrentPosition() {
        let userCurrentPosition;
        navigator.geolocation.getCurrentPosition(position => {userCurrentPosition = position;});
        console.log('--> user current position:',userCurrentPosition);
        return userCurrentPosition;
    }

    /**
     * A last ditch fall back when no center point can be found!
     * @return {{accountId: string, accountAddress: string, accountName: string, latitude: number, longitude: number}}
     */
    getDefaultCenterGeo() {
        return {
            latitude:41.7958534,
            longitude:-88.0747337,
            accountAddress: '300 Adams Street, Oak Park, IL United States',
            accountName: 'Oak Park Center',
            accountId : '1'
        };
    }
}