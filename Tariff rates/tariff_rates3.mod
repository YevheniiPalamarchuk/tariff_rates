// Sets
int TimePeriods = 5;
int GeneratorTypes = 3;
range T = 1..TimePeriods;
range G = 1..GeneratorTypes;

// Parameters
int demand[T] = [15000, 30000, 25000, 40000, 27000];
int minLevel[G] = [850, 1250, 1500];
int maxLevel[G] = [2000, 1750, 4000];
int minCost[G] = [1000, 2600, 3000];
float costPerMWAboveMin[G] = [2.0, 1.3, 3.0];
int startupCost[G] = [2000, 1000, 500];
int numUnits[G] = [12, 10, 5];
int HoursPerPeriod[T] = [6, 3, 6, 3, 6]; // Hours in each time period

// Decision Variables
dvar float+ x[G][T]; // Total output rate from generators of type i in period j
dvar int+ n[G][T]; // Number of generating units of type i working in period j
dvar int+ s[G][T]; // Number of generators of type i started up in period j

// Additional Decision Expression for cost per period
dexpr float costPerPeriod[j in T] = 
    sum(i in G) (
        costPerMWAboveMin[i] * HoursPerPeriod[j] * (x[i][j] - minLevel[i] * n[i][j])
        + minCost[i] * HoursPerPeriod[j] * n[i][j]
        + startupCost[i] * s[i][j]
    );
    
    // Additional Decision Expression for cost per 1 MW per period
dexpr float costPerMWPerPeriod[j in T] = costPerPeriod[j] / sum(i in G) x[i][j];
    


// Objective Function
dexpr float totalCost = sum(j in T) costPerPeriod[j];

minimize totalCost;

// Constraints
subject to {
    // Demand must be met in each period
    forall(j in T)
        sum(i in G) (x[i][j]) >= demand[j];
        
    // Output must lie within the limits of the generators working
    forall(i in G, j in T) {
        x[i][j] >= minLevel[i]*n[i][j];
        x[i][j] <= maxLevel[i]*n[i][j];
    }
    
    // Extra guaranteed load requirement
    forall(j in T) {
        sum(i in G) (maxLevel[i]*n[i][j]) >= demand[j] * 1.15;
    }
    
    // The number of generators started in period
    forall(i in G, j in T) {
        s[i][j] >= n[i][j] - (j == 1 ? n[i][TimePeriods] : n[i][j-1]); // If j = 1 then j-1 -> TimePeriods
    }
    
    // Upper bounds for the number of generators used for each type in each time period
    forall(i in G, j in T)
        n[i][j] <= round(numUnits[i]);

    // Upper bounds for the number of generators started up in each time period
    forall(i in G, j in T)
        s[i][j] <= round(numUnits[i]);	
}

// Calculating cost per 1 MW of energy
dexpr float totalEnergyGenerated = sum(i in G, j in T) x[i][j];
dexpr float costPerMW = totalCost / totalEnergyGenerated;

// Output cost per period and cost per MW
execute {
    writeln("Cost per period: ", costPerPeriod);
    writeln("Total cost: ", totalCost);
    writeln("Total energy generated: ", totalEnergyGenerated);
    writeln("Cost per 1 MW: ", costPerMW);
}
// Divide cost per period by hours per period to get cost per hour
execute {
    writeln("Cost per hour for each period:");
    for (var j in T) {
        writeln("Period ", j, ": ", costPerPeriod[j] / HoursPerPeriod[j] / demand[j]);
    }
}

