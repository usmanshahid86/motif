export async function getApps() {
  const response = await fetch(
    "https://bitdsm-app-indexer-production.up.railway.app/apps"
  );
  const data = await response.json();
  return data as Array<{
    id: string;
    name: string;
    description: string;
    url: string;
    block: number;
    txHash: string;
    logo: string;
  }>;
}
