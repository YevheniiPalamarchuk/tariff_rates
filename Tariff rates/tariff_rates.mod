/*********************************************
 * OPL 22.1.1.0 Model
 * Author: yevhe
 * Creation Date: 31 maj 2024 at 11:18:00
 *********************************************/


// Sets
int TimePeriods = 5;
int GeneratorTypes = 3;
int MaxUnits = 12; // Assuming the maximum number of units across all types is 12
range T = 1..TimePeriods;
range G = 1..GeneratorTypes;
range U = 1..MaxUnits; // Define a range for units

// Parameters
int demand[T] = [15000, 30000, 25000, 40000, 27000];
int minLevel[G] = [850, 1250, 1500];
int maxLevel[G] = [2000, 1750, 4000];
int minCost[G] = [1000, 2600, 3000];
float costPerMWAboveMin[G] = [2.0, 1.3, 3.0];
int startupCost[G] = [2000, 1000, 500];
int numUnits[G] = [12, 10, 5];

// Decision Variables
dvar boolean x[T][G][U]; // Whether unit u of type g is on during period t
dvar float+ y[T][G][U]; // Power output of unit u of type g above minimum level during period t

// Objective Function
dexpr float totalCost = 
  sum(t in T, g in G, u in 1..numUnits[g]) (
    x[t][g][u] * minCost[g] + 
    y[t][g][u] * costPerMWAboveMin[g]
  );

minimize totalCost;

// Constraints
subject to {
  // Meet demand with reserve capacity
  forall(t in T)
    sum(g in G, u in 1..numUnits[g]) (x[t][g][u] * minLevel[g] + y[t][g][u]) >= demand[t] * 1.15;
  
  // Maintain power output within limits
  forall(t in T, g in G, u in 1..numUnits[g]) {
    y[t][g][u] <= (maxLevel[g] - minLevel[g]) * x[t][g][u];
  }
}
