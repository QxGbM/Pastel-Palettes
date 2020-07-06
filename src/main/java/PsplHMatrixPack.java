
import java.lang.System.Logger;

public class PsplHMatrixPack {

  public static final double EPI = 1.e-10;
  public static final int MINIMAL_SEP = 512;

  private static int rank = 16;
  private static int level = 3;
  private static int nblocks = 2;
  private static int nleaf = 128;
  private static int dim = nleaf * (int) Math.pow (nblocks, level);
  private static double admis = 0.5;

  private static final Logger logger = System.getLogger("logger");

  @FunctionalInterface
  public interface DataFunction
  { public double body (int i, int j); }

  static final DataFunction testFunc = (int i, int j) -> {
    int diff = Math.abs(i - j);
    return 1. / (1. + diff); 
  };
  
  public static void main (String[] args) {

    parse(args);

    boolean integrity = level >= 1 && nblocks >= 1 && dim >= 0 && admis >= 0;

    if (integrity) {
      Dense d = new Dense (dim, dim, 0, 0, testFunc);

      Hierarchical h = new Hierarchical(dim, dim, nleaf, nblocks, admis, 0, 0, testFunc);

      ClusterBasis rb = new ClusterBasis(h, true, 16);
      ClusterBasis cb = new ClusterBasis(h, false, 16);

      H2Matrix h2 = new H2Matrix(rb, cb, 0, 0, admis, testFunc);

      rb.convertReducedStorageForm();
      cb.convertReducedStorageForm();

      //H2Matrix h2 = new H2Matrix(dim, dim, nleaf, nblocks, rank, admis, 0, 0, testFunc);
      infoOut("compress: " + h2.toDense().minus(d).normF() / dim / dim);

      long startTime = System.nanoTime();
      h2.getrf();
      long endTime = System.nanoTime();
      infoOut("H2-LU time: " +  (endTime - startTime) / 1000000);

      d.getrf();
      infoOut("LU Err: " + h2.toDense().minus(d).normF() / dim / dim);

      double compress = h2.getCompressionRatio();
      infoOut("h Storage Compression Ratio: " + Double.toString(compress));

    }

  }

  
  private static void parse (String[] args) {
    StringBuilder sum = new StringBuilder();

    for (int i = 0; i < args.length; i++)
    {
      if (args[i].startsWith("-level="))
      { level = Integer.parseInt(args[i].substring(7)); }
      else if (args[i].startsWith("-nblocks="))
      { nblocks = Integer.parseInt(args[i].substring(9)); }
      else if (args[i].startsWith("-nleaf="))
      { nleaf = Integer.parseInt(args[i].substring(7)); dim = nleaf * (int) Math.pow (nblocks, level); }
      else if (args[i].startsWith("-dim="))
      { dim = Integer.parseInt(args[i].substring(5)); nleaf = dim / (int) Math.pow (nblocks, level); }
      else if (args[i].startsWith("-admis="))
      { admis = Integer.parseInt(args[i].substring(7)); }
      else if (args[i].startsWith("-rank="))
      { rank = Integer.parseInt(args[i].substring(6)); }
      else 
      { sum.append("Ignored arg: " + args[i] + "\n"); }
    }

    sum.append("level: " + Integer.toString(level) + "\n");
    sum.append("nblocks: " + Integer.toString(nblocks) + "\n");
    sum.append("nleaf: " + Integer.toString(nleaf) + "\n");
    sum.append("dim: " + Integer.toString(dim) + "\n");
    sum.append("admis: " + Double.toString(admis) + "\n");
    sum.append("rank: " + Integer.toString(rank) + "\n");

    logger.log(System.Logger.Level.INFO, sum.toString());
  }

  public static void infoOut (String msg) {
    logger.log(System.Logger.Level.INFO, msg);
  }

  public static void errorOut (String msg) {
    logger.log(System.Logger.Level.ERROR, msg);
    System.exit(-1);
  }


}
