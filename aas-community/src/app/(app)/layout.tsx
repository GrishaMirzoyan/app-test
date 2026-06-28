import { requireVerified } from "@/lib/gate";
import NavBar from "@/components/NavBar";

// Every page under (app) is behind the verification gate (§1, §4.8).
export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const me = await requireVerified();
  return (
    <div className="min-h-screen">
      <NavBar isAdmin={me.isAdmin} />
      <main className="mx-auto max-w-5xl px-4 py-8">{children}</main>
    </div>
  );
}
