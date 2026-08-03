import Link from 'next/link'

export default function DashboardLayout({ children }) {
    return(
        <div>
            <nav>
                <Link href="/dashboard">Dashboard</Link>
                <Link href="/drivers">Drivers</Link>
                <Link href="/zones">Zones</Link>
            </nav>
            <main>{children}</main>
        </div>
    )
}