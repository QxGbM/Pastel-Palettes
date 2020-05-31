import java.io.*;
import Jama.Matrix;

public interface Block {

  enum Block_t { DENSE, LOW_RANK, HIERARCHICAL }

  abstract public int getXCenter();

  abstract public int getYCenter();

  abstract public void setClusterStart(int x_start, int y_start);

  abstract public int getRowDimension();

  abstract public int getColumnDimension();

  abstract public Block_t getType();
		
  abstract public Dense toDense();

  abstract public LowRank toLowRank();

  abstract public LowRankBasic toLowRankBasic();

  abstract public Hierarchical castHierarchical();

  abstract public H2Matrix castH2Matrix();

  abstract public void setAccumulator(LowRankBasic accm);

  abstract public LowRankBasic getAccumulator();

  abstract public boolean equals (Block b);

  public abstract double compare (Matrix m);

  abstract public double getCompressionRatio ();

  abstract public double getCompressionRatio_NoBasis ();

  abstract public String structure ();

  abstract public void loadBinary (InputStream stream) throws IOException;

  abstract public void writeBinary (OutputStream stream) throws IOException;

  abstract public void writeToFile (String name) throws IOException;

  abstract public void print (int w, int d);

  abstract public Block LU ();

  abstract public Block triangularSolve (Block b, boolean up_low);
  
  abstract public Block GEMatrixMult (Block a, Block b, double alpha, double beta);

  abstract public Block GEMatrixMult (Block a, Block b, double alpha, double beta, ClusterBasisProduct X, ClusterBasisProduct Y, ClusterBasisProduct Z, H2Approx Sa, H2Approx Sb, H2Approx Sc);

  abstract public Block plusEquals (Block b);

  abstract public Block scalarEquals (double s);

  abstract public Block times (Block b);

  abstract public Block accum (LowRankBasic accm);

  public static Block readStructureFromFile (BufferedReader reader) throws IOException {
    String str = reader.readLine();
    String[] args = str.split("\\s+");
    int m = Integer.parseInt(args[1]);
    int n = Integer.parseInt(args[2]);

    if (str.startsWith("D")) {
      Dense d = new Dense(m, n);
      return d;
    }
    else if (str.startsWith("LR")) {
      int r = Integer.parseInt(args[3]);
      LowRank lr = new LowRank(m, n, r);
      return lr;
    }
    else if (str.startsWith("H")) {
      Hierarchical h = new Hierarchical(m, n);

      for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++)
        { h.setElement(i, j, readStructureFromFile(reader)); }
      }

      return h;
    }
    else
    { return null; } 

  }

}
