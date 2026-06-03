"""
Debug script to test OpenStreetMap API directly
"""
import asyncio
import httpx

async def test_osm_api():
    """Test OpenStreetMap API directly"""
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        
        # Test 1: Nominatim geocoding
        print("=" * 60)
        print("TEST 1: Nominatim Geocoding")
        print("=" * 60)
        
        #hean

        test_addresses = [
            "Egyptian Museum Cairo Egypt",
            "Tahrir Cairo Egypt",
            "Midan al Tahrir Cairo Egypt",
            "Khan el Khalili Cairo Egypt",
            "Al Azhar Park Cairo Egypt"
        ]

        for address in test_addresses:
            print(f"\nTesting: {address}")

            response = await client.get(
                "https://nominatim.openstreetmap.org/search",
                params={
                    "q": address,
                    "format": "json",
                    "limit": 3
                },
                headers={
                    "User-Agent": "SmartExplorers/1.0"
                }
            )

            results = response.json()

            print(f"Results: {len(results)}")

            if results:
                print(results[0]["display_name"])



        response = await client.get(
            "https://nominatim.openstreetmap.org/search",
            params={
                "q": address,
                "format": "json",
                "limit": 1,
                "addressdetails": 1
            },
            headers={"User-Agent": "SmartExplorers/1.0"}
        )
        
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            results = response.json()
            if results:
                print(f"✓ Found: {results[0].get('display_name')[:100]}")
                print(f"  Lat: {results[0].get('lat')}, Lon: {results[0].get('lon')}")
            else:
                print("✗ No results found")
        else:
            print(f"✗ Failed: {response.text[:200]}")
        
        print("\n" + "=" * 60)
        print("TEST 2: Overpass API - Search for 'Egyptian Museum'")
        print("=" * 60)
        
        lat = 30.0478
        lon = 31.2335
        
        # Try exact match
        query = f"""
        [out:json][timeout:10];
        (
          node["name"="Egyptian Museum"](around:1000,{lat},{lon});
          way["name"="Egyptian Museum"](around:1000,{lat},{lon});
        );
        out center body;
        """
        
        response = await client.post(
            "https://overpass-api.de/api/interpreter",
            content=query,
            headers={
                "User-Agent": "SmartExplorers/1.0",
                "Content-Type": "text/plain",
                "Accept": "application/json"
            },
            timeout=30.0
        )
        
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            elements = data.get("elements", [])
            print(f"Found {len(elements)} exact matches")
            for elem in elements[:3]:
                tags = elem.get('tags', {})
                print(f"  - Name: {tags.get('name', 'N/A')}")
        else:
            print(f"✗ Failed: {response.text[:200]}")
        
        print("\n" + "=" * 60)
        print("TEST 3: Overpass API - Fuzzy search for 'museum'")
        print("=" * 60)
        
        # Try fuzzy search
        query = f"""
        [out:json][timeout:10];
        (
          node["name"~"museum",i](around:1000,{lat},{lon});
          way["name"~"museum",i](around:1000,{lat},{lon});
        );
        out center body 5;
        """
        
        response = await client.post(
            "https://overpass-api.de/api/interpreter",
            content=query,
            headers={
                "User-Agent": "SmartExplorers/1.0",
                "Content-Type": "text/plain",
                "Accept": "application/json"
            },
            timeout=30.0
        )
        
        if response.status_code == 200:
            data = response.json()
            elements = data.get("elements", [])
            print(f"Found {len(elements)} fuzzy matches")
            for elem in elements[:5]:
                tags = elem.get('tags', {})
                lat_val = elem.get('lat', elem.get('center', {}).get('lat', 'N/A'))
                lon_val = elem.get('lon', elem.get('center', {}).get('lon', 'N/A'))
                print(f"  - {tags.get('name', 'N/A')} at ({lat_val}, {lon_val})")
        else:
            print(f"✗ Failed")

if __name__ == "__main__":
    asyncio.run(test_osm_api())