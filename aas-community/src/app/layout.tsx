import type { Metadata } from "next";
import "./globals.css";

// Default-private (§1): instruct crawlers not to index, belt-and-suspenders with
// the X-Robots-Tag header set in next.config.mjs.
export const metadata: Metadata = {
  title: "AAS Community",
  description: "A private community for Penguins.",
  robots: { index: false, follow: false },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
