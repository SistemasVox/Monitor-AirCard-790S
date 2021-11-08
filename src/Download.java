import java.io.BufferedReader;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.net.URL;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.util.ArrayList;

public class Download {
	static ArrayList<String> listadeStrings = new ArrayList<>();
	public static void main(String[] args) {
		new Thread(new Runnable() {
			@Override
			public void run() {
				do {
					try {
						download();
						Thread.sleep(5000);
					} catch (InterruptedException e) {
						System.out.println(e.toString());
					}
				} while (true);
			}
		}).start();
	}

	private static void download() {
		try {
			URL website = new URL("http://192.168.1.1/about.txt?save=about.txt");
			ReadableByteChannel rbc = Channels.newChannel(website.openStream());
			@SuppressWarnings("resource")
			FileOutputStream fos = new FileOutputStream("about.txt");
			fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
			escrever();
		} catch (Exception e) {
			System.out.println(e.getMessage());
		}
	}

	private static void escrever() {
		try {
			FileReader arq = new FileReader("about.txt");
			@SuppressWarnings("resource")
			BufferedReader lerArq = new BufferedReader(arq);
			String linha = lerArq.readLine();
			listadeStrings.clear();
			while (linha != null) {
				listadeStrings.add(linha);
				linha = lerArq.readLine();
			}
			for (int i = 40; i < 45; i++) {
				System.out.println(listadeStrings.get(i).replaceAll("[^0-9]+", ""));
			}
		} catch (Exception e) {
			System.out.println(e.getMessage());
		}
	}
}