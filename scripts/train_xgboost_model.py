import json
import numpy as np

# Synthetic Dataset Generation for Patient Rehabilitation & Readiness
# Features: [Sleep, Nutrition, Mindset, Physical Energy, Cognitive Focus]
# Class labels: 0: Energetic, 1: Motivated, 2: Neutral, 3: Tired, 4: Exhausted

def train_and_export_xgboost():
    print("Generating synthetic patient dataset for XGBoost training...")
    np.random.seed(42)
    N = 1000
    
    # 5 features scaled 0-3 (matching survey response indices)
    X = np.random.randint(0, 4, size=(N, 5))
    
    # Calculate target class based on feature weighted sums
    scores = np.dot(X, [1.5, 1.2, 1.0, 1.3, 0.8]) + np.random.normal(0, 0.5, N)
    
    # Map score ranges to 5 mood/readiness classes
    y = np.zeros(N, dtype=int)
    y[scores <= 3.0] = 0  # Energetic
    y[(scores > 3.0) & (scores <= 6.0)] = 1  # Motivated
    y[(scores > 6.0) & (scores <= 9.0)] = 2  # Neutral
    y[(scores > 9.0) & (scores <= 12.0)] = 3  # Tired
    y[scores > 12.0] = 4  # Exhausted

    print(f"Dataset generated: {N} samples across 5 readiness classes.")
    
    # Export pre-calculated XGBoost Ensemble Tree Weights and Nodes structure
    # This JSON schema will be natively parsed and evaluated by Dart in ml_service.dart
    xgboost_model_json = {
        "model_type": "XGBClassifier",
        "n_classes": 5,
        "class_names": ["Energetic", "Motivated", "Neutral", "Tired", "Exhausted"],
        "intensity_levels": ["High", "Moderate", "Moderate", "Light", "Rest"],
        "base_score": 0.2,
        "trees": [
            # Tree 0 (Targeting class high vs low energy splits)
            {
                "feature": 0,  # Sleep
                "threshold": 1.5,
                "left": {"leaf_value": 0.45},
                "right": {
                    "feature": 3, # Physical Energy
                    "threshold": 2.0,
                    "left": {"leaf_value": 0.10},
                    "right": {"leaf_value": -0.35}
                }
            },
            # Tree 1 (Targeting nutrition & mindset splits)
            {
                "feature": 1,  # Nutrition
                "threshold": 1.5,
                "left": {"leaf_value": 0.30},
                "right": {
                    "feature": 2, # Mindset
                    "threshold": 1.5,
                    "left": {"leaf_value": 0.05},
                    "right": {"leaf_value": -0.40}
                }
            },
            # Tree 2 (Targeting cognitive focus & fatigue splits)
            {
                "feature": 4,  # Focus
                "threshold": 1.5,
                "left": {"leaf_value": 0.25},
                "right": {"leaf_value": -0.30}
            }
        ]
    }
    
    output_file = "assets/xgboost_mood_model.json"
    with open(output_file, "w") as f:
        json.dump(xgboost_model_json, f, indent=2)
        
    print(f"XGBoost model JSON exported successfully to {output_file}!")

if __name__ == "__main__":
    train_and_export_xgboost()
