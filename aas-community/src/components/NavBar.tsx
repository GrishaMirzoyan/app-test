import Link from "next/link";
import SignOutButton from "./SignOutButton";

const LINKS = [
  { href: "/dashboard", label: "Home" },
  { href: "/directory", label: "Directory" },
  { href: "/map", label: "Hall of Flags" },
  { href: "/library", label: "Library" },
  { href: "/chat", label: "Cafeteria" },
];

export default function NavBar({ isAdmin }: { isAdmin: boolean }) {
  return (
    <header className="sticky top-0 z-10 border-b border-ice-200 bg-white/90 backdrop-blur">
      <nav className="mx-auto flex max-w-5xl items-center gap-1 px-4 py-3">
        <Link href="/dashboard" className="mr-2 text-lg">
          🐧
        </Link>
        {LINKS.map((l) => (
          <Link
            key={l.href}
            href={l.href}
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-deep-700 hover:bg-ice-100"
          >
            {l.label}
          </Link>
        ))}
        <div className="ml-auto flex items-center gap-1">
          {isAdmin && (
            <Link
              href="/admin"
              className="rounded-lg px-3 py-1.5 text-sm font-medium text-deep-700 hover:bg-ice-100"
            >
              Admin
            </Link>
          )}
          <Link
            href="/settings"
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-deep-700 hover:bg-ice-100"
          >
            Settings
          </Link>
          <SignOutButton />
        </div>
      </nav>
    </header>
  );
}
