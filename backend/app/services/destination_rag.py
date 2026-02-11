"""
RAG Service with ChromaDB for Egypt Destinations
Semantic search over destinations data
"""
import json
from pathlib import Path
from typing import List, Dict, Any, Optional
import chromadb
from chromadb.config import Settings
from chromadb.utils import embedding_functions


class DestinationRAG:
    """RAG system for semantic search over Egypt destinations"""
    
    def __init__(self):
        """Initialize ChromaDB and load destinations"""
        
        # Initialize ChromaDB client (persistent storage)
        self.client = chromadb.PersistentClient(
            path="./chroma_db",
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        
        # Use sentence transformers for embeddings (free, local)
        self.embedding_function = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="all-MiniLM-L6-v2"  # Fast, good quality
        )
        
        # Get or create collection
        self.collection_name = "egypt_destinations"
        try:
            self.collection = self.client.get_collection(
                name=self.collection_name,
                embedding_function=self.embedding_function
            )
            print(f"✓ Loaded existing ChromaDB collection: {self.collection_name}")
        except:
            self.collection = self.client.create_collection(
                name=self.collection_name,
                embedding_function=self.embedding_function,
                metadata={"description": "Egypt tourism destinations with semantic search"}
            )
            print(f"✓ Created new ChromaDB collection: {self.collection_name}")
            # Load and index destinations
            self._load_and_index_destinations()
    
    def _load_and_index_destinations(self):
        """Load destinations from JSON and index in ChromaDB"""
        
        try:
            # Load JSON file
            current_dir = Path(__file__).parent.parent
            json_path = current_dir / "data" / "egypt_destinations.json"
            
            if not json_path.exists():
                print(f"⚠️  Warning: {json_path} not found")
                return
            
            with open(json_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            destinations = data.get("destinations", [])
            
            if not destinations:
                print("⚠️  No destinations found in JSON")
                return
            
            # Prepare data for ChromaDB
            documents = []
            metadatas = []
            ids = []
            
            for i, dest in enumerate(destinations):
                # Create rich text representation for embedding
                doc_text = self._create_destination_text(dest)
                documents.append(doc_text)
                
                # Store metadata
                metadatas.append({
                    "name": dest["name"],
                    "safety_level": dest.get("safety_level", "medium"),
                    "accessibility": dest.get("accessibility", "moderate"),
                    "best_time": dest.get("best_time", "Oct-Apr"),
                    "avg_budget_low": dest.get("avg_daily_budget", {}).get("low", 30),
                    "avg_budget_mid": dest.get("avg_daily_budget", {}).get("mid", 70),
                    "avg_budget_high": dest.get("avg_daily_budget", {}).get("high", 150),
                    "description": dest.get("description", ""),
                    "attractions": json.dumps(dest.get("attractions", [])),  # Store as JSON string
                })
                
                ids.append(f"dest_{i}")
            
            # Add to ChromaDB (with embeddings)
            self.collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids
            )
            
            print(f"✓ Indexed {len(destinations)} destinations in ChromaDB")
            
        except Exception as e:
            print(f"⚠️  Error indexing destinations: {e}")
    
    def _create_destination_text(self, dest: Dict[str, Any]) -> str:
        """Create rich text representation for semantic search"""
        
        name = dest["name"]
        description = dest.get("description", "")
        attractions = ", ".join(dest.get("attractions", []))
        safety = dest.get("safety_level", "medium")
        accessibility = dest.get("accessibility", "moderate")
        best_time = dest.get("best_time", "")
        
        # Create comprehensive text for embedding
        text = f"""
        Destination: {name}
        Description: {description}
        Main Attractions: {attractions}
        Safety Level: {safety}
        Accessibility: {accessibility}
        Best Time to Visit: {best_time}
        """
        
        return text.strip()
    
    def search_destinations(
        self,
        query: str,
        n_results: int = 5,
        filters: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Semantic search for destinations
        
        Args:
            query: Natural language query (e.g., "ancient temples with good accessibility")
            n_results: Number of results to return
            filters: Optional metadata filters (e.g., {"safety_level": "high"})
        
        Returns:
            List of matching destinations with metadata
        """
        
        # Build where clause for filtering
        where_clause = None
        if filters:
            # ChromaDB requires $and for multiple conditions
            if len(filters) > 1:
                where_clause = {"$and": []}
                for key, value in filters.items():
                    where_clause["$and"].append({key: value})
            else:
                where_clause = filters
        
        # Query ChromaDB
        results = self.collection.query(
            query_texts=[query],
            n_results=n_results,
            where=where_clause
        )
        
        # Format results
        destinations = []
        if results and results['metadatas']:
            for metadata in results['metadatas'][0]:
                # Parse attractions back from JSON
                metadata['attractions'] = json.loads(metadata.get('attractions', '[]'))
                destinations.append(metadata)
        
        return destinations
    
    def get_destinations_by_names(self, destination_names: List[str]) -> List[Dict[str, Any]]:
        """Get full destination data by name"""
        
        destinations = []
        
        for name in destination_names:
            # Query by exact name match
            results = self.collection.get(
                where={"name": name}
            )
            
            if results and results['metadatas']:
                metadata = results['metadatas'][0]
                metadata['attractions'] = json.loads(metadata.get('attractions', '[]'))
                destinations.append(metadata)
        
        return destinations
    
    def get_destinations_for_preferences(
        self,
        interests: List[str],
        budget_max: Optional[float] = None,
        accessibility_required: bool = False,
        safety_level: Optional[str] = None,
        n_results: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Get destinations matching user preferences
        
        Args:
            interests: User interests (e.g., ["history", "photography", "adventure"])
            budget_max: Maximum daily budget
            accessibility_required: Whether high accessibility is required
            safety_level: Minimum safety level ("high", "medium", "low")
            n_results: Number of results
        
        Returns:
            List of matching destinations
        """
        
        # Build query from interests
        query = " ".join(interests)
        
        # Build filters as a list for $and operator
        filter_conditions = []
        
        if budget_max:
            # Filter by budget (using mid-range as reference)
            filter_conditions.append({"avg_budget_mid": {"$lte": budget_max}})
        
        if accessibility_required:
            filter_conditions.append({"accessibility": "high"})
        
        if safety_level:
            # Safety levels: high > medium > low
            if safety_level == "high":
                filter_conditions.append({"safety_level": "high"})
            elif safety_level == "medium":
                filter_conditions.append({"safety_level": {"$in": ["high", "medium"]}})
        
        # Build final where clause
        where_clause = None
        if filter_conditions:
            if len(filter_conditions) > 1:
                where_clause = {"$and": filter_conditions}
            else:
                where_clause = filter_conditions[0]
        
        # Search
        return self.search_destinations(
            query=query,
            n_results=n_results,
            filters=where_clause
        )
    
    def reset_database(self):
        """Reset ChromaDB (useful for updates)"""
        try:
            self.client.delete_collection(name=self.collection_name)
            print(f"✓ Deleted collection: {self.collection_name}")
            self.__init__()  # Reinitialize
        except:
            pass


# Global instance
destination_rag = DestinationRAG()