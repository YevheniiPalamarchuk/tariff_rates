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


///// Objective Function
dexpr float totalCost = 
  sum(i in G, j in T) (
   costPerMWAboveMin[i]*HoursPerPeriod[j]*(x[i][j] - minLevel[i]*n[i][j]))
   + sum (i in G, j in T) (minCost[i]*HoursPerPeriod[j]*n[i][j])
   + sum (i in G, j in T) (startupCost[i]*s[i][j])
;

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
    forall(i in G, j in T) {
        sum(i in G) (maxLevel[i]*n[i][j]) >= demand[j] * 1.15;
    }
    
    // The number of generators started in period
    forall(i in G, j in T) {
        s[i][j] >= n[i][j] - (j == 1 ? n[i][5] : n[i][j-1]); // If j = 1 then j-1 -> 5
    }
    
	// Upper bounds for the number of generators used for each type in each time period
	forall(t in T, i in G)
    	n[i][t] <= round(numUnits[i]);

	// Upper bounds for the number of generators started up in each time period
	forall(t in T, i in G)
    	s[i][t] <= round(numUnits[i]);
    	
}

