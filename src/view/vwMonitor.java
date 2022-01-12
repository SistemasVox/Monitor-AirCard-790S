package view;

import java.awt.EventQueue;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.border.EmptyBorder;
import utils.AePlayWave;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.SwingConstants;
import java.awt.event.ActionListener;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.awt.event.ActionEvent;
import java.awt.Font;
import javax.swing.JTextField;
import javax.swing.JTextArea;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.Color;
import javax.swing.JRadioButton;

@SuppressWarnings("serial")
public class vwMonitor extends JFrame {
	private JPanel contentPane;
	private static JTextField txt0;
	private static JTextField txt1;
	private static JTextField txtVolts;
	private static JTextField txt3;
	private static JTextField txt4;
	private static JTextField txt5;
	private static ArrayList<JTextField> jt = new ArrayList<>();
	private static ArrayList<String> listadeStrings = new ArrayList<>();
	private JTextField txtTime;
	private boolean continuar = true, continuar_ping = true;
	private static JTextArea txtArea;
	private static int contagem = 0;
	private JTextField ping0;
	private JTextField ping1;
	private JTextField ping2;
	private JTextField ping3;
	private Process process;
	private JLabel lblHora;
	private static JRadioButton rdSom, rdCustomPing;
	private static JLabel lblT1;
	private static JLabel lblT2;
	private static JLabel lblBat;
	private static int min = 990, med = 0, max = 0, c_s = 0, time_ping = 60, mv = 4300, mvB = 4300;
	private static ArrayList<Integer> medA = new ArrayList<>();
	private static String s, ms, temp1 = "99", temp2 = "99", bat = "100";
	private JLabel lblg;
	private static vwError404 erro;

	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					vwMonitor frame = new vwMonitor();
					frame.setVisible(true);
				} catch (Exception e) {
					erro(e.getMessage());
				}
			}
		});
	}

	public vwMonitor() {
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setBounds(100, 100, 457, 300);
		contentPane = new JPanel();
		contentPane.setBorder(new EmptyBorder(5, 5, 5, 5));
		setContentPane(contentPane);
		JButton btnStart = new JButton("Começar");
		btnStart.setBounds(10, 228, 135, 23);
		btnStart.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				if (continuar) {
					audio_Play("Windows XP Startup", true);
					btnStart.setEnabled(false);
					new Thread(new Runnable() {
						@Override
						public void run() {
							do {
								try {
									download();
									Thread.sleep(Integer.parseInt(txtTime.getText().toString()));
									if (contagem > 3) {
										contagem = 0;
									}
									txtArea.setText("Monitorando" + (pontos(contagem)));
									contagem++;
								} catch (InterruptedException e) {
									erro(e.getMessage());
								}
							} while (continuar);
						}
					}).start();
				} else {
					txtArea.setText("Continuar False.");
				}
			}
		});
		contentPane.setLayout(null);
		contentPane.add(btnStart);
		JButton btnStop = new JButton("Parar");
		btnStop.setBounds(155, 228, 89, 23);
		btnStop.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				if (continuar) {
					continuar = false;
				} else {
					continuar = true;
					btnStart.setEnabled(true);
				}
			}
		});
		contentPane.add(btnStop);
		JButton btnExit = new JButton("Sair");
		btnExit.setBounds(353, 228, 89, 23);
		btnExit.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				if (process != null) {
					process.destroy();
				}
				System.exit(EXIT_ON_CLOSE);
			}
		});
		lblT1 = new JLabel("x");
		lblT1.setVerticalAlignment(SwingConstants.BOTTOM);
		lblT1.setHorizontalAlignment(SwingConstants.LEFT);
		lblT1.setFont(new Font("Tahoma", Font.BOLD, 14));
		lblT1.setBounds(265, 64, 36, 14);
		contentPane.add(lblT1);
		lblT2 = new JLabel("x");
		lblT2.setVerticalAlignment(SwingConstants.BOTTOM);
		lblT2.setHorizontalAlignment(SwingConstants.LEFT);
		lblT2.setFont(new Font("Tahoma", Font.BOLD, 14));
		lblT2.setBounds(265, 165, 36, 14);
		contentPane.add(lblT2);
		contentPane.add(btnExit);
		JLabel lblPower = new JLabel("Power State:");
		lblPower.setBounds(10, 39, 154, 14);
		lblPower.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblPower);
		JLabel lblTemperatura = new JLabel("Current temperature:");
		lblTemperatura.setBounds(10, 64, 154, 14);
		lblTemperatura.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblTemperatura);
		JLabel lblVoltagem = new JLabel("Current voltage:");
		lblVoltagem.setBounds(10, 89, 154, 14);
		lblVoltagem.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblVoltagem);
		JLabel lblBateriaProcetagem = new JLabel("Battery charge level:");
		lblBateriaProcetagem.setBounds(10, 114, 154, 14);
		lblBateriaProcetagem.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblBateriaProcetagem);
		JLabel lblBateriaStatus = new JLabel("Battery status:");
		lblBateriaStatus.setBounds(10, 139, 154, 14);
		lblBateriaStatus.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblBateriaStatus);
		JLabel lblBateriaTemperatura = new JLabel("Battery temperature:");
		lblBateriaTemperatura.setBounds(10, 164, 154, 14);
		lblBateriaTemperatura.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblBateriaTemperatura);
		JLabel lblTitulo = new JLabel("Monitor de Temperatura AirCard 790S");
		lblTitulo.setBounds(10, 11, 414, 14);
		lblTitulo.setFont(new Font("Times New Roman", Font.BOLD, 14));
		lblTitulo.setHorizontalAlignment(SwingConstants.CENTER);
		contentPane.add(lblTitulo);
		JLabel lblStatusApp = new JLabel("Status App:");
		lblStatusApp.setBounds(10, 203, 89, 14);
		lblStatusApp.setFont(new Font("Tahoma", Font.BOLD, 12));
		contentPane.add(lblStatusApp);
		txt0 = new JTextField();
		txt0.setBounds(177, 37, 86, 20);
		jt.add(txt0);
		txt0.setText("00");
		txt0.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt0.setHorizontalAlignment(SwingConstants.CENTER);
		txt0.setEditable(false);
		contentPane.add(txt0);
		txt0.setColumns(10);
		txt1 = new JTextField();
		txt1.setBounds(177, 62, 86, 20);
		jt.add(txt1);
		txt1.setText("00");
		txt1.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt1.setHorizontalAlignment(SwingConstants.CENTER);
		txt1.setEditable(false);
		txt1.setColumns(10);
		contentPane.add(txt1);
		txtVolts = new JTextField();
		txtVolts.setBounds(177, 87, 86, 20);
		jt.add(txtVolts);
		txtVolts.setText("00");
		txtVolts.setFont(new Font("Tahoma", Font.BOLD, 14));
		txtVolts.setHorizontalAlignment(SwingConstants.CENTER);
		txtVolts.setEditable(false);
		txtVolts.setColumns(10);
		contentPane.add(txtVolts);
		txt3 = new JTextField();
		txt3.setBounds(177, 112, 86, 20);
		jt.add(txt3);
		txt3.setText("00");
		txt3.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt3.setHorizontalAlignment(SwingConstants.CENTER);
		txt3.setEditable(false);
		txt3.setColumns(10);
		contentPane.add(txt3);
		txt4 = new JTextField();
		txt4.setBounds(177, 137, 86, 20);
		jt.add(txt4);
		txt4.setText("00");
		txt4.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt4.setHorizontalAlignment(SwingConstants.CENTER);
		txt4.setEditable(false);
		txt4.setColumns(10);
		contentPane.add(txt4);
		txt5 = new JTextField();
		txt5.setBounds(177, 162, 86, 20);
		jt.add(txt5);
		txt5.setText("00");
		txt5.setFont(new Font("Tahoma", Font.BOLD, 14));
		txt5.setHorizontalAlignment(SwingConstants.CENTER);
		txt5.setEditable(false);
		txt5.setColumns(10);
		contentPane.add(txt5);
		txtTime = new JTextField();
		txtTime.setBounds(356, 203, 86, 20);
		txtTime.setText("1000");
		txtTime.setFont(new Font("Tahoma", Font.BOLD, 14));
		txtTime.setHorizontalAlignment(SwingConstants.CENTER);
		contentPane.add(txtTime);
		txtTime.setColumns(10);
		txtArea = new JTextArea();
		txtArea.setFont(new Font("Monospaced", Font.BOLD, 14));
		txtArea.setWrapStyleWord(true);
		txtArea.setLineWrap(true);
		txtArea.setEditable(false);
		txtArea.setBounds(96, 203, 250, 22);
		contentPane.add(txtArea);
		JButton btnPing = new JButton("Ping");
		btnPing.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				new Thread(new Runnable() {
					@Override
					public void run() {
						try {
							if (continuar_ping) {
								btnPing.setEnabled(false);
								ping();
							} else {
								txtArea.setText("Continuar FALSE");
							}
						} catch (IOException e) {
							erro(e.getMessage() + " " + hora());
						}
					}
				}).start();
			}
		});
		btnPing.setBounds(254, 228, 89, 23);
		contentPane.add(btnPing);
		lblg = new JLabel("GoogleBR:");
		lblg.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseClicked(MouseEvent e) {
				if (continuar_ping) {
					continuar_ping = false;
					if (process != null) {
						process.destroy();
					}
				} else {
					continuar_ping = true;
					btnPing.setEnabled(true);
				}
			}
		});
		lblg.setHorizontalAlignment(SwingConstants.RIGHT);
		lblg.setFont(new Font("Tahoma", Font.BOLD, 12));
		lblg.setBounds(273, 39, 79, 14);
		contentPane.add(lblg);
		ping0 = new JTextField();
		ping0.setText("00");
		ping0.setHorizontalAlignment(SwingConstants.CENTER);
		ping0.setFont(new Font("Tahoma", Font.BOLD, 14));
		ping0.setEditable(false);
		ping0.setColumns(10);
		ping0.setBounds(353, 37, 86, 20);
		contentPane.add(ping0);
		JLabel lblmin = new JLabel("Min:");
		lblmin.setHorizontalAlignment(SwingConstants.RIGHT);
		lblmin.setFont(new Font("Tahoma", Font.BOLD, 12));
		lblmin.setBounds(316, 64, 36, 14);
		contentPane.add(lblmin);
		ping1 = new JTextField();
		ping1.setText("00");
		ping1.setHorizontalAlignment(SwingConstants.CENTER);
		ping1.setFont(new Font("Tahoma", Font.BOLD, 14));
		ping1.setEditable(false);
		ping1.setColumns(10);
		ping1.setBounds(353, 62, 86, 20);
		contentPane.add(ping1);
		JLabel lblmed = new JLabel("Med:");
		lblmed.setHorizontalAlignment(SwingConstants.RIGHT);
		lblmed.setFont(new Font("Tahoma", Font.BOLD, 12));
		lblmed.setBounds(316, 89, 36, 14);
		contentPane.add(lblmed);
		ping2 = new JTextField();
		ping2.setText("00");
		ping2.setHorizontalAlignment(SwingConstants.CENTER);
		ping2.setFont(new Font("Tahoma", Font.BOLD, 14));
		ping2.setEditable(false);
		ping2.setColumns(10);
		ping2.setBounds(353, 87, 86, 20);
		contentPane.add(ping2);
		ping3 = new JTextField();
		ping3.setText("00");
		ping3.setHorizontalAlignment(SwingConstants.CENTER);
		ping3.setFont(new Font("Tahoma", Font.BOLD, 14));
		ping3.setEditable(false);
		ping3.setColumns(10);
		ping3.setBounds(353, 112, 86, 20);
		contentPane.add(ping3);
		JLabel lblmax = new JLabel("Max:");
		lblmax.addMouseListener(new MouseAdapter() {
			@Override
			public void mouseClicked(MouseEvent e) {
				try {
					time_ping = Integer.parseInt(JOptionPane.showInputDialog("Novo tempo de ping?")) * 60;
					erro("Novo tempo de ping: " + time_ping + "s.");
				} catch (Exception e2) {
					time_ping = 60;
					erro("Erro de tempo de ping, novo ping: " + time_ping + "s.");
				}
			}
		});
		lblmax.setHorizontalAlignment(SwingConstants.RIGHT);
		lblmax.setFont(new Font("Tahoma", Font.BOLD, 12));
		lblmax.setBounds(316, 114, 36, 14);
		contentPane.add(lblmax);
		lblHora = new JLabel("New label");
		lblHora.setHorizontalAlignment(SwingConstants.RIGHT);
		lblHora.setFont(new Font("Tahoma", Font.BOLD, 14));
		lblHora.setText(new SimpleDateFormat("hh:mm:ss").format(new Date()));
		lblHora.setBounds(330, 137, 105, 14);
		contentPane.add(lblHora);
		rdSom = new JRadioButton("Som ON");
		rdSom.setHorizontalAlignment(SwingConstants.RIGHT);
		rdSom.setBounds(356, 175, 86, 23);
		contentPane.add(rdSom);
		lblBat = new JLabel("");
		lblBat.setVerticalAlignment(SwingConstants.BOTTOM);
		lblBat.setHorizontalAlignment(SwingConstants.LEFT);
		lblBat.setFont(new Font("Tahoma", Font.BOLD, 14));
		lblBat.setBounds(265, 114, 36, 14);
		contentPane.add(lblBat);
		rdCustomPing = new JRadioButton("Ping");
		rdCustomPing.setHorizontalAlignment(SwingConstants.RIGHT);
		rdCustomPing.setBounds(265, 175, 86, 23);
		contentPane.add(rdCustomPing);
	}

	private static void download() {
		try {
			excluirARQ();
			URL website = new URL("http://192.168.1.1/about.txt?save=about.txt");
			ReadableByteChannel rbc = Channels.newChannel(website.openStream());
			@SuppressWarnings("resource")
			FileOutputStream fos = new FileOutputStream("about.txt");
			fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
			escrever();
		} catch (Exception e) {
			erro(e.getMessage() + " " + hora());
		}
	}

	private static void excluirARQ() {
		if (new File("about.txt").exists()) {
			new File("about.txt").delete();
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
			for (int i = 39; i < 45; i++) {
				String[] st = listadeStrings.get(i).split(":");
				if (i == 40 || i == 44) {
					jt.get(i - 39).setText(st[1].trim().replaceAll("[^0-9]+", "") + "°");
					if (i == 40) {
						if (!temp1.equals(st[1].trim().replaceAll("[^0-9]+", ""))) {
							corSomDevice(st[1].trim().replaceAll("[^0-9]+", ""));
							if (Integer.parseInt(st[1].trim().replaceAll("[^0-9]+", "")) > Integer.parseInt(temp1)) {
								lblT1.setText("+");
							} else {
								lblT1.setText("-");
							}
							temp1 = st[1].trim().replaceAll("[^0-9]+", "");
						}
					}
					if (i == 44) {
						if (!temp2.equals(st[1].trim().replaceAll("[^0-9]+", ""))) {
							corSomBeterry(st[1].trim().replaceAll("[^0-9]+", ""));
							if (Integer.parseInt(st[1].trim().replaceAll("[^0-9]+", "")) > Integer.parseInt(temp2)) {
								lblT2.setText("+");
							} else {
								lblT2.setText("-");
							}
							temp2 = st[1].trim().replaceAll("[^0-9]+", "");
						}
					}
				} else {
					jt.get(i - 39).setText(st[1].trim());
				}
				if (i == 42) {
					if (!bat.equals(st[1].trim().replaceAll("[^0-9]+", ""))) {
						if (Integer.parseInt(st[1].trim().replaceAll("[^0-9]+", "")) > Integer.parseInt(bat)) {
							lblBat.setText("+");
							lblBat.setForeground(new Color(0, 0, 255));
							audio_Play("Windows XP Balloon", rdSom.isSelected());
						} else {
							lblBat.setText("-");
							lblBat.setForeground(new Color(255, 69, 0));
							audio_Play("Windows XP Balloon", true);
						}
						bat = st[1].trim().replaceAll("[^0-9]+", "");
					}
				}
				if (i == 41) {
					if (Integer.parseInt(st[1].trim().replaceAll("[^0-9]+", "")) != mvB) {
						mvB = Integer.parseInt(st[1].trim().replaceAll("[^0-9]+", ""));
						if (Integer.parseInt(st[1].trim().replaceAll("[^0-9]+", "")) > mv) {
							txtVolts.setForeground(new Color(255, 69, 0));
							audio_Play("Windows XP Balloon", rdSom.isSelected());
						} else if (Integer.parseInt(st[1].trim().replaceAll("[^0-9]+", "")) > mv + mv * 0.1) {
							txtVolts.setForeground(new Color(255, 0, 0));
							audio_Play("Windows XP Balloon", true);
						} else {
							txtVolts.setForeground(new Color(0, 0, 0));
						}
					}
				}
			}
		} catch (Exception e) {
			erro(e.getMessage());
		}
	}

	public static void erro(String msg) {
		if (erro == null) {
			erro = new vwError404(msg);
			erro.setVisible(true);
		} else {
			erro.setVisible(true);
			erro.msg(msg);
		}
	}

	private static void corSomDevice(String temp_1) {
		int t = Integer.parseInt(temp_1);
		if (t > 40) {
			txt1.setForeground(new Color(139, 0, 0));
			audio_Play("Windows XP Shutdown", true);
		} else if (t <= 40 && t > 35) {
			txt1.setForeground(new Color(255, 45, 33));
			audio_Play("classic notify", rdSom.isSelected());
		} else if (t <= 35 && t > 30) {
			txt1.setForeground(new Color(0, 0, 0));
			audio_Play("classic notify", rdSom.isSelected());
		} else if (t < 30) {
			txt1.setForeground(new Color(0, 0, 255));
			audio_Play("classic notify", rdSom.isSelected());
		}
	}

	private static void corSomBeterry(String temp_1) {
		int t = Integer.parseInt(temp_1);
		if (t > 35) {
			txt5.setForeground(new Color(139, 0, 0));
			audio_Play("Windows XP Shutdown", true);
		} else if (t <= 35 && t > 33) {
			txt5.setForeground(new Color(255, 45, 33));
			audio_Play("Windows XP Battery Low", rdSom.isSelected());
		} else if (t <= 33 && t > 30) {
			txt5.setForeground(new Color(226, 144, 0));
			audio_Play("Windows XP Battery Low", rdSom.isSelected());
		} else if (t <= 30 && t > 25) {
			txt5.setForeground(new Color(0, 0, 0));
			audio_Play("Windows XP Battery Low", rdSom.isSelected());
		} else {
			txt5.setForeground(new Color(0, 0, 255));
			audio_Play("Windows XP Battery Low", rdSom.isSelected());
		}
	}

	private static void audio_Play(String nome, boolean on) {
		if (on) {
			File f = new File("sons/" + nome + ".wav");
			new AePlayWave(f.getAbsolutePath()).start();
		}
	}

	private String pontos(int contagem) {
		String s = "";
		for (int i = 0; i < contagem; i++) {
			s += ".";
		}
		return s;
	}

	private void ping() throws IOException {
		List<String> commands = new ArrayList<String>();
		if (System.getProperty("os.name").matches(".*indows.*")) {
			if (rdCustomPing.isSelected()) {
				String[] comando = JOptionPane.showInputDialog(null, "Qual o comando do Ping?").split(" ");
				for (int i = 0; i < comando.length; i++) {
					commands.add(comando[i]);
				}
				lblg.setText("Custom:");
				lblg.setToolTipText(comando[comando.length - 1]);
			} else {
				commands.add("ping");
				commands.add("-t");
				commands.add("-l");
				commands.add("756");
				commands.add("8.8.4.4");
			}
		} else if (System.getProperty("os.name").matches(".*inux.*")) {
			if (rdCustomPing.isSelected()) {
				String[] comando = JOptionPane.showInputDialog(null, "Qual o comando do Ping?").split(" ");
				for (int i = 0; i < comando.length; i++) {
					commands.add(comando[i]);
				}
				lblg.setText("Custom:");
				lblg.setToolTipText(comando[comando.length - 1]);
			} else {
				commands.add("ping");
				commands.add("-s");
				commands.add("756");
				commands.add("1.0.0.1");
				lblg.setText("Cloudflare:");
			}
		}
		google(commands);
	}

	private void google(List<String> commands) throws IOException {
		s = "";
		ProcessBuilder pb = new ProcessBuilder(commands);
		process = pb.start();
		BufferedReader stdInput = new BufferedReader(new InputStreamReader(process.getInputStream()));
		while ((s = stdInput.readLine()) != null) {
			if (continuar_ping) {
				if (s.matches(".*ms.*")) {
					String[] sp = s.split("=");
					for (int i = 0; i < sp.length; i++) {
						if (sp[i].matches(".*ms.*")) {
							ms = sp[i].trim().replaceAll("[^0-9]+", "");
							pingSom(ms);
						}
					}
					ping0.setText(ms + "ms");
					colorPing(ping0, Integer.parseInt(ms));
					minMedMax();
				}
			} else {
				process.destroy();
				zerar_ping();
			}
		}
	}

	private void pingSom(String ping) {
		if (Integer.parseInt(ping) > 1500) {
			audio_Play("windows xp pop-up blocked", rdSom.isSelected());
		}
	}

	private void minMedMax() {
		if (c_s > time_ping) {
			zerar_ping();
		} else {
			c_s++;
		}
		int ms_att = Integer.parseInt(ms);
		if (ms_att > max) {
			max = ms_att;
		}
		if (ms_att < min) {
			min = ms_att;
		}
		if (med != -1) {
			medA.add(ms_att);
			int medT = 0;
			for (int i = 0; i < medA.size(); i++) {
				medT += medA.get(i);
			}
			med = (medT / medA.size());
		} else {
			medA.clear();
			medA.add(ms_att);
			min = ms_att;
			med = medA.get(0);
			max = ms_att;
		}
		ping1.setText(min + "ms");
		colorPing(ping1, min);
		ping2.setText(med + "ms");
		colorPing(ping2, med);
		ping3.setText(max + "ms");
		colorPing(ping3, max);
	}

	private void colorPing(JTextField ping, int valor) {
		if (valor > 100) {
			ping.setForeground(new Color(255, 0, 0));
		} else if (valor <= 100 && valor > 75) {
			ping.setForeground(new Color(0, 0, 0));
		} else if (valor <= 75) {
			ping.setForeground(new Color(0, 0, 255));
		}
	}

	private void zerar_ping() {
		c_s = 0;
		min = 999;
		max = 0;
		med = -1;
		ping0.setText("--");
		ping1.setText("--");
		ping2.setText("--");
		ping3.setText("--");
		lblHora.setText(hora());
	}

	private static String hora() {
		return new SimpleDateFormat("hh:mm:ss").format(new Date());
	}
}