"use client";

import { useState } from "react";
import Link from "next/link";

export interface CityGroup {
  city: string;
  country: string;
  lat: number;
  lng: number;
  members: { id: string; name: string; label: string }[];
}

// A dependency-free equirectangular pin plot. City-level pins ONLY (§1) — pins
// sit at city centroids, never at member coordinates. Tap a city to list the
// Penguins there ("who's near me").
const W = 720;
const H = 360;

function project(lat: number, lng: number): { x: number; y: number } {
  return { x: ((lng + 180) / 360) * W, y: ((90 - lat) / 180) * H };
}

export default function MapView({ groups }: { groups: CityGroup[] }) {
  const [selected, setSelected] = useState<CityGroup | null>(null);

  return (
    <div className="grid gap-4 lg:grid-cols-[2fr_1fr]">
      <div className="card overflow-hidden p-2">
        <svg
          viewBox={`0 0 ${W} ${H}`}
          className="w-full rounded-lg bg-ice-100"
          role="img"
          aria-label="World map of Penguins by city"
        >
          {/* Graticule for orientation (no tile server needed). */}
          {[...Array(11)].map((_, i) => (
            <line
              key={`v${i}`}
              x1={(i / 10) * W}
              y1={0}
              x2={(i / 10) * W}
              y2={H}
              stroke="#c3def0"
              strokeWidth={0.5}
            />
          ))}
          {[...Array(7)].map((_, i) => (
            <line
              key={`h${i}`}
              x1={0}
              y1={(i / 6) * H}
              x2={W}
              y2={(i / 6) * H}
              stroke="#c3def0"
              strokeWidth={0.5}
            />
          ))}
          {/* Equator + prime meridian, slightly darker. */}
          <line x1={0} y1={H / 2} x2={W} y2={H / 2} stroke="#92c4e3" strokeWidth={0.8} />
          <line x1={W / 2} y1={0} x2={W / 2} y2={H} stroke="#92c4e3" strokeWidth={0.8} />

          {groups.map((g) => {
            const { x, y } = project(g.lat, g.lng);
            const r = Math.min(14, 5 + g.members.length * 1.5);
            const active = selected?.city === g.city && selected?.country === g.country;
            return (
              <g key={`${g.city}|${g.country}`} className="cursor-pointer">
                <circle
                  cx={x}
                  cy={y}
                  r={r}
                  fill={active ? "#0d2438" : "#13314f"}
                  fillOpacity={0.75}
                  stroke="white"
                  strokeWidth={1}
                  onClick={() => setSelected(g)}
                />
                <text x={x} y={y + 3} textAnchor="middle" fontSize={9} fill="white">
                  {g.members.length}
                </text>
              </g>
            );
          })}
        </svg>
        {groups.length === 0 && (
          <p className="p-4 text-center text-sm text-deep-700/60">
            No city pins yet — be the first to drop one in Settings.
          </p>
        )}
      </div>

      <div className="card">
        {selected ? (
          <>
            <div className="flex items-center justify-between">
              <h2 className="font-medium">
                {selected.city}, {selected.country}
              </h2>
              <Link
                className="text-xs text-deep-700/60 underline"
                href={`/directory?city=${encodeURIComponent(selected.city)}`}
              >
                Open in directory
              </Link>
            </div>
            <ul className="mt-3 space-y-2">
              {selected.members.map((m) => (
                <li key={m.id}>
                  <Link href={`/members/${m.id}`} className="block rounded-lg bg-ice-50 p-2 text-sm hover:bg-ice-100">
                    <span className="font-medium">{m.name}</span>
                    <span className="block text-xs text-deep-700/60">{m.label}</span>
                  </Link>
                </li>
              ))}
            </ul>
          </>
        ) : (
          <p className="text-sm text-deep-700/60">
            Tap a city pin to see who&apos;s there.
          </p>
        )}
      </div>
    </div>
  );
}
