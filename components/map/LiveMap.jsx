"use client";

import { MapContainer, TileLayer, GeoJSON } from "react-leaflet";
import "leaflet/dist/leaflet.css";

export default function LiveMap({ zones }) {
  return (
    <MapContainer
      center={[5.6037, -0.1870]}
      zoom={12}
      style={{ height: "500px", width: "100%" }}
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
      />
      {zones.map((zone) => (
        <GeoJSON key={zone.id} data={zone.polygon} />
      ))}
    </MapContainer>
  );
}